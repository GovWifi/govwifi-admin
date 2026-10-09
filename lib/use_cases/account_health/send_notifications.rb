require "logger"

module UseCases
  module AccountHealth
    # Emails an organisation once when an account health issue is detected, and again only if it is
    # resolved and then recurs. Failed sends are retried on later runs.
    #
    # Only logs what it would do unless ACCOUNT_HEALTH_EMAILS_ENABLED=true.
    # ACCOUNT_HEALTH_EMAILS_ORGANISATION_IDS (comma-separated) limits the run to those organisations.
    class SendNotifications
      Finding = Struct.new(:organisation_id, :issue, keyword_init: true)

      def self.enabled?
        ENV.fetch("ACCOUNT_HEALTH_EMAILS_ENABLED", "false") == "true"
      end

      def self.organisation_ids_from_env
        ENV["ACCOUNT_HEALTH_EMAILS_ORGANISATION_IDS"].presence&.split(",")&.map { |id| Integer(id.strip) }
      end

      def initialize(logger: Logger.new($stdout), enabled: self.class.enabled?,
                     organisation_ids: self.class.organisation_ids_from_env)
        @logger = logger
        @enabled = enabled
        @organisations = organisation_ids ? ::Organisation.where(id: organisation_ids) : ::Organisation.all
      end

      def execute
        findings = find_issues
        return log_dry_run(findings) unless @enabled

        now = Time.zone.now
        resolve_cleared(findings, now)
        findings.each { |finding| record(finding, now) }
        deliver_pending
      end

    private

      def find_issues
        checks = Checks.new(@organisations)
        Checks::RULES.flat_map do |rule|
          checks.organisation_ids(rule).map { |id| Finding.new(organisation_id: id, issue: rule.to_s) }
        end
      end

      def resolve_cleared(findings, now)
        current_keys = findings.to_set { |f| AccountHealthNotification.open_key_for(f.organisation_id, f.issue) }
        AccountHealthNotification.open.where(organisation: @organisations).find_each do |notification|
          next if current_keys.include?(notification.open_key)

          notification.resolve!(at: now)
          @logger.info("Account health: resolved #{notification.issue} for organisation #{notification.organisation_id}")
        end
      end

      def record(finding, now)
        open_key = AccountHealthNotification.open_key_for(finding.organisation_id, finding.issue)
        notification = AccountHealthNotification.find_by(open_key:)

        AccountHealthNotification.transaction do
          if notification
            # Already emailed, or still waiting for someone to email.
            add_recipients(notification, now) if notification.uncontactable_at.present?
          else
            notification = AccountHealthNotification.create!(
              organisation_id: finding.organisation_id,
              issue: finding.issue,
              open_key:,
              detected_at: now,
            )
            add_recipients(notification, now)
          end
        end
      rescue ActiveRecord::RecordNotUnique
        nil # another run recorded this first
      end

      def add_recipients(notification, now)
        users = eligible_recipients(notification.organisation_id, notification.issue)

        if users.any?
          users.each { |user| notification.recipients.create!(user:, email_address: user.email) }
          notification.update!(uncontactable_at: nil)
        elsif notification.uncontactable_at.nil?
          notification.update!(uncontactable_at: now)
          @logger.warn("Account health: nobody to email about #{notification.issue} for organisation #{notification.organisation_id}; recorded for support")
        end
      end

      # Confirmed users with an accepted membership who can fix the issue: anyone who can manage
      # locations for location issues, otherwise administrators.
      def eligible_recipients(organisation_id, issue)
        permissions = if issue == "missing_location_details"
                        { can_manage_locations: true }
                      else
                        { can_manage_team: true, can_manage_locations: true }
                      end
        User
          .joins(:memberships)
          .where(memberships: { organisation_id:, **permissions })
          .where.not(memberships: { confirmed_at: nil })
          .where.not(confirmed_at: nil)
          .distinct
          .order(:id)
          .to_a
      end

      def deliver_pending
        AccountHealthNotificationRecipient
          .retryable
          .joins(:account_health_notification)
          .merge(AccountHealthNotification.open.where(organisation: @organisations))
          .includes(account_health_notification: :organisation)
          .find_each { |recipient| deliver(recipient) }
      end

      # Locks the recipient so that overlapping runs cannot both send the same email.
      def deliver(recipient)
        notification = recipient.account_health_notification

        recipient.with_lock do
          next if recipient.sent_at.present? || recipient.attempts >= AccountHealthNotificationRecipient::MAX_ATTEMPTS

          unless eligible_recipients(notification.organisation_id, notification.issue).map(&:id).include?(recipient.user_id)
            recipient.update!(attempts: AccountHealthNotificationRecipient::MAX_ATTEMPTS, last_error: "No longer eligible")
            next
          end

          begin
            GovWifiMailer.account_health_notification(recipient.email_address, notification.issue, notification.organisation).deliver_now
            recipient.update!(sent_at: Time.zone.now, attempts: recipient.attempts + 1, last_error: nil)
          rescue StandardError => e
            recipient.update!(attempts: recipient.attempts + 1, last_error: "#{e.class}: #{e.message}".truncate(255))
            @logger.error("Account health: failed to email recipient #{recipient.id} (attempt #{recipient.attempts}): #{e.class}: #{e.message}")
          end
        end
      end

      def log_dry_run(findings)
        @logger.info("Account health emails are disabled (set ACCOUNT_HEALTH_EMAILS_ENABLED=true to send). Nothing recorded or sent.")
        findings.group_by(&:issue).each do |issue, issue_findings|
          recipient_counts = issue_findings.map { |f| eligible_recipients(f.organisation_id, issue).size }
          @logger.info("Account health (dry run): #{issue}: #{issue_findings.size} organisations, " \
                       "#{recipient_counts.sum} recipients, #{recipient_counts.count(&:zero?)} with nobody to email")
        end
      end
    end
  end
end
