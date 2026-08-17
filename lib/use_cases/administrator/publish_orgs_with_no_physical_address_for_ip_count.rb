require "logger"

module UseCases
  module Administrator
    class PublishOrgsWithNoPhysicalAddressForIpCount
      METRIC_NAME = "account-health-orgs-with-no-physical-address-for-ip-count".freeze
      S3_FOLDER = "account-health-orgs-with-no-physical-address-for-ip-count".freeze

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
        @metric ||= ::Location
          .where("(postcode IS NULL OR postcode = '' OR LOWER(postcode) = 'unknown') AND (address IS NULL OR address = '' OR LOWER(address) = 'unknown')")
          .count
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
        @logger.info("END: Writing to S3 bucket - (Orgs with no physical address for IP count: #{metric})")
      end

      def send_to_api
        @logger.info("BEGIN: Posting to metrics API...")
        UseCases::PerformancePlatform::MetricsApiPublisher.publish(stats)
        @logger.info("END: Posting to metrics API - (Orgs with no physical address for IP count: #{metric})")
      end
    end
  end
end
