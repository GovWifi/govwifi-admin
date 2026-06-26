require "logger"

module UseCases
  module Administrator
    class PublishOrganisationCount
      def initialize(logger: Logger.new($stdout))
        @logger = logger
      end

      def publish
        send_to_s3
        send_to_api
      end

    private

      def metric
        ::Organisation.count(:name)
      end

      def stats
        {
          metric_name: "organisation-count",
          count: metric,
          run_time: Time.zone.today,
        }
      end

      def send_to_s3
        @logger.info("BEGIN: Writing to S3 bucket...")
        Gateways::S3.new(**Gateways::S3::S3_METRICS_BUCKET).write(stats.to_yaml)
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
