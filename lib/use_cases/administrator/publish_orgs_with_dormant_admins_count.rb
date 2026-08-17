require "logger"

module UseCases
  module Administrator
    class PublishOrgsWithDormantAdminsCount
      METRIC_NAME = "account-health-orgs-with-dormant-admins-count".freeze
      S3_FOLDER = "account-health-orgs-with-dormant-admins-count".freeze
      DORMANT_AFTER = 365.days

      def initialize(logger: Logger.new($stdout))
        @logger = logger
      end

      def publish
        send_to_s3
        send_to_api
      end

    private

      def today
        @today ||= Time.zone.today
      end

      def metric
        @metric ||= ::Organisation
          .joins(memberships: :user)
          .where(memberships: { can_manage_locations: true, can_manage_team: true })
          .where.not(name: nil)
          .where("users.last_sign_in_at < ? OR users.last_sign_in_at IS NULL", DORMANT_AFTER.ago)
          .group(:name)
          .having("COUNT(*) < 2")
          .count
          .size
      end

      def stats
        {
          metric_name: METRIC_NAME,
          count: metric,
          run_time: today,
        }
      end

      def s3_key
        "#{S3_FOLDER}/orgs-with-dormant-admins-count-#{today.iso8601}"
      end

      def s3_payload
        {
          count: metric,
          metric_name: METRIC_NAME,
          period: "day",
          date: today.iso8601,
        }
      end

      def send_to_s3
        @logger.info("BEGIN: Writing to S3 bucket...")
        Gateways::S3.new(bucket: ENV.fetch("S3_METRICS_BUCKET"), key: s3_key).write("#{s3_payload.to_json}\n")
        @logger.info("END: Writing to S3 bucket - (Orgs with dormant admins count: #{metric})")
      end

      def send_to_api
        @logger.info("BEGIN: Posting to metrics API...")
        UseCases::PerformancePlatform::MetricsApiPublisher.publish(stats)
        @logger.info("END: Posting to metrics API - (Orgs with dormant admins count: #{metric})")
      end
    end
  end
end
