require "logger"

module UseCases
  module Administrator
    class PublishOrganisationCount
      def initialize(logger: Logger.new($stdout))
        @logger = logger
      end

      def publish
        return if stats.nil?

        send_to_s3
        send_to_api
      end

    private

      METRIC_NAME = "acount-health-organisation-count".freeze

      def metric
        ::Organisation.count(:name)
      end

      def stats
        {
          metric_name: METRIC_NAME,
          count: metric,
          run_time: Time.zone.today,
        }
      end

      def key
        "account_health_organisation_count/organisation_count-#{Time.zone.today}"
      end

      def send_to_s3
        @logger.info("BEGIN: Writing to S3 bucket...")
        bucket = ENV.fetch("S3_METRICS_BUCKET")
        Gateways::S3.new(bucket: bucket, key: key).write(stats.to_json)
        @logger.info("END: Writing to S3 bucket - (Org count: #{stats[:count]})")
      end

      def send_to_api
        @logger.info("BEGIN: Posting to metrics API...")
        UseCases::PerformancePlatform::MetricsApiPublisher.publish(stats)
        @logger.info("END: Posting to metrics API - (Org count: #{stats[:count]})")
      end
    end
  end
end
