# frozen_string_literal: true

require "logger"

module UseCases
  module Administrator
    class PublishUserSignups
      def self.execute(date: Time.zone.today, logger: Logger.new($stdout))
        new(date:, logger:).publish
      end

      def initialize(date: Time.zone.today, logger: Logger.new($stdout))
        @date = date.is_a?(String) ? Date.parse(date) : date
        @logger = logger
      end

      def publish
        Performance::Metrics::UserSignupsMetricSender::STATS.each_key do |metric|
          metric_sender = Performance::Metrics::UserSignupsMetricSender.new(
            date: @date,
            metric:,
            logger: @logger,
          )
          @logger.info("BEGIN: [#{metric_sender.key}] Fetching and uploading user signups metrics...")
          metric_sender.to_s3
          metric_sender.to_api
          @logger.info("END: [#{metric_sender.key}] Done.")
        end
      end

      alias_method :execute, :publish
    end
  end
end
