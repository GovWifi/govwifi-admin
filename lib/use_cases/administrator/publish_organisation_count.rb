require "logger"

module UseCases
  module Administrator
    class PublishOrganisationCount
      def publish
        logger = Logger.new($stdout)
        count = ::Organisation.count(:name)
        metric = {
          metric_name: "organisation-count",
          count: count,
          run_time: Time.zone.today,
        }

        logger.info("BEGIN: Writing to S3 bucket...")
        Gateways::S3.new(**Gateways::S3::S3_METRICS_BUCKET).write(metric.to_yaml)
        logger.info("END: Writing to S3 bucket")

        logger.info("BEGIN: Posting to metrics API...")
        UseCases::PerformancePlatform::MetricsApiPublisher.publish(metric)
        logger.info("END: Posting to metrics API")
      end
    end
  end
end
