require "logger"

module UseCases
  module Administrator
    class PublishOrgsHaveNoActiveAdminsCount
      METRIC_NAME = "account-health-orgs-have-no-active-admins-count".freeze
      S3_FOLDER = "account-health-orgs-have-no-active-admins-count".freeze
      ACTIVE_WITHIN = 1.year

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

      # The inner join filters to admin memberships before grouping, so an org with zero
      # admin memberships never forms a group and is excluded rather than counted as "0".
      def metric
        @metric ||= ::Organisation
          .joins(memberships: :user)
          .where(memberships: { can_manage_locations: true, can_manage_team: true })
          .where.not(name: nil)
          .group(:name)
          .having(
            "COUNT(*) < 2 AND SUM(CASE WHEN users.last_sign_in_at >= ? THEN 1 ELSE 0 END) = 0",
            ACTIVE_WITHIN.ago,
          )
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
        "#{S3_FOLDER}/#{METRIC_NAME}-#{today.iso8601}"
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
        @logger.info("END: Writing to S3 bucket - (Orgs with no active admins count: #{metric})")
      end

      def send_to_api
        @logger.info("BEGIN: Posting to metrics API...")
        UseCases::PerformancePlatform::MetricsApiPublisher.publish(stats)
        @logger.info("END: Posting to metrics API - (Orgs with no active admins count: #{metric})")
      end
    end
  end
end
