module UseCases
  module AccountHealth
    # The super admin Account health worklist. Combines the live rules with the recorded emails so
    # each organisation with an issue gets one entry, most urgent first. Read only.
    class Worklist
      # Most urgent first. The first five are shown on the worklist; the rest have not been notified yet.
      STATUSES = %i[
        cannot_notify
        notification_failed
        overdue
        follow_up_due
        recently_notified
        retrying
        not_emailed
      ].freeze
      LISTED_STATUSES = STATUSES.first(5).freeze

      Entry = Struct.new(:organisation, :issues, :no_active_administrators, keyword_init: true) do
        # One line per rule. For inactive administrators, the most urgent of their individual statuses.
        def lines
          issues.group_by(&:issue).values.map { |same| same.min_by(&:sort_key) }
        end

        # The lines shown on the worklist. Issues not notified yet are left out.
        def listed_lines
          lines.select { |line| LISTED_STATUSES.include?(line.status) }
        end

        def listed?
          no_active_administrators || listed_lines.any?
        end

        # Organisations we cannot notify come first, then those with no active administrators, then the
        # longest outstanding.
        def sort_key
          rank, date = lines.map(&:sort_key).min
          rank = [rank, 0.5].min if no_active_administrators
          [rank, date, organisation.name]
        end
      end

      Issue = Struct.new(:issue, :status, :first_notified_at, :recorded_at, keyword_init: true) do
        def sort_key
          [STATUSES.index(status).to_f, first_notified_at || recorded_at || Time.zone.now]
        end
      end

      # Under one calendar month is recent; one to three calendar months, inclusive, is due a follow-up.
      def self.email_age_status(first_notified_at, now: Time.zone.now)
        if first_notified_at > now - 1.month
          :recently_notified
        elsif first_notified_at >= now - 3.months
          :follow_up_due
        else
          :overdue
        end
      end

      def initialize(organisations = ::Organisation.all, now: Time.zone.now)
        @checks = Checks.new(organisations)
        @organisations = organisations
        @now = now
      end

      def entries
        @entries ||= issues_by_organisation.map { |organisation_id, issues|
          Entry.new(
            organisation: organisations_by_id.fetch(organisation_id),
            issues:,
            no_active_administrators: no_active_administrator_ids.include?(organisation_id),
          )
        }.sort_by(&:sort_key)
      end

    private

      def issues_by_organisation
        Checks::RULES.flat_map { |rule|
          @checks.organisation_ids(rule).flat_map { |organisation_id| issues_for(organisation_id, rule.to_s) }
        }.group_by(&:first).transform_values { |pairs| pairs.map(&:last) }
      end

      def issues_for(organisation_id, issue)
        if issue == "inactive_administrator"
          inactive_memberships.fetch(organisation_id, []).map { |membership| [organisation_id, inactive_administrator_issue(membership)] }
        else
          [[organisation_id, organisation_issue(organisation_id, issue)]]
        end
      end

      def organisation_issue(organisation_id, issue)
        notification = notifications[[organisation_id, issue]]
        recipients = notification&.recipients.to_a
        sent_at = recipients.filter_map(&:sent_at).min
        status =
          if sent_at
            self.class.email_age_status(sent_at, now: @now)
          elsif people_for(organisation_id, issue).none? { |membership| eligible?(membership) }
            :cannot_notify
          else
            sending_status(recipients)
          end

        recorded_at = status == :cannot_notify ? notification&.uncontactable_at : notification&.detected_at
        Issue.new(issue:, status:, first_notified_at: sent_at, recorded_at:)
      end

      # The inactive administrator issue is recorded once per organisation, so an administrator only
      # has their own email date if they were one of the people emailed when it was first recorded.
      def inactive_administrator_issue(membership)
        notification = notifications[[membership.organisation_id, "inactive_administrator"]]
        recipient = notification&.recipients&.find { |r| r.user_id == membership.user_id }
        status =
          if recipient&.sent_at
            self.class.email_age_status(recipient.sent_at, now: @now)
          elsif !eligible?(membership)
            :cannot_notify
          else
            sending_status([recipient].compact)
          end

        Issue.new(issue: "inactive_administrator", status:, first_notified_at: recipient&.sent_at, recorded_at: notification&.detected_at)
      end

      # Not sending because email is switched off or the organisation is outside the rollout is not a failure.
      def sending_status(recipients)
        if recipients.empty?
          :not_emailed
        elsif recipients.all? { |r| r.attempts >= AccountHealthNotificationRecipient::MAX_ATTEMPTS }
          :notification_failed
        else
          :retrying
        end
      end

      # Who would be emailed about an issue, matching UseCases::AccountHealth::SendNotifications.
      def people_for(organisation_id, issue)
        members = memberships.fetch(organisation_id, [])
        issue == "missing_location_details" ? members.select(&:can_manage_locations?) : members.select(&:administrator?)
      end

      def eligible?(membership)
        membership.confirmed_at.present? && membership.user.confirmed_at.present?
      end

      def no_active_administrator_ids
        @no_active_administrator_ids ||= begin
          counts = @checks.confirmed_administrator_counts
          counts.keys.select { |id| inactive_memberships.fetch(id, []).size >= counts[id] }
        end
      end

      def inactive_memberships
        @inactive_memberships ||= @checks.inactive_administrators.to_a.group_by(&:organisation_id)
      end

      def notifications
        @notifications ||= AccountHealthNotification.open.where(organisation: @organisations)
          .includes(:recipients).index_by { |n| [n.organisation_id, n.issue] }
      end

      def memberships
        @memberships ||= ::Membership.where(organisation_id: organisation_ids).includes(:user).to_a.group_by(&:organisation_id)
      end

      def organisations_by_id
        @organisations_by_id ||= ::Organisation.where(id: organisation_ids).index_by(&:id)
      end

      def organisation_ids
        @organisation_ids ||= Checks::RULES.flat_map { |rule| @checks.organisation_ids(rule) }.uniq
      end
    end
  end
end
