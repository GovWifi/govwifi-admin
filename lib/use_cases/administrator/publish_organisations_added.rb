# frozen_string_literal: true

require "logger"

module UseCases
  module Administrator
    class PublishOrganisationsAdded
      def initialize(date: Time.zone.today, logger: Logger.new($stdout))
        @date = date.is_a?(String) ? Date.parse(date) : date
        @logger = logger
      end

      def publish
        Performance::Metrics::OrganisationsAddedMetricSender::STATS.each_key do |metric|
          metric_sender = Performance::Metrics::OrganisationsAddedMetricSender.new(
            date: @date,
            metric:,
            logger: @logger,
          )
          @logger.info("BEGIN: [#{metric_sender.key}] Fetching and uploading organisations added metrics...")
          metric_sender.to_s3
          metric_sender.to_api
          @logger.info("END: [#{metric_sender.key}] Done.")
        end
      end
    end
  end
end
