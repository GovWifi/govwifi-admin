# frozen_string_literal: true

require "logger"

module UseCases::Administrator
  class PublishLocationsAdded
    METRICS = %i[
      monthly_rolling_locations_added
      month_to_date_locations_added
    ].freeze

    def self.execute(date: Time.zone.today, logger: Logger.new($stdout))
      new(date:, logger:).execute
    end

    def initialize(date: Time.zone.today, logger: Logger.new($stdout))
      @date = date
      @logger = logger
    end

    def execute
      METRICS.each do |metric|
        sender = Performance::Metrics::LocationsAddedMetricSender.new(metric:, date: @date, logger: @logger)
        @logger.info("BEGIN: [#{sender.key}] Fetching and uploading locations added metrics...")
        sender.to_s3
        sender.to_api
        @logger.info("END: [#{sender.key}] Done.")
      end
    end
  end
end
