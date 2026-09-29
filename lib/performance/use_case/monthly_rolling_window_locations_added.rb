# frozen_string_literal: true

module Performance::UseCase
  class MonthlyRollingWindowLocationsAdded
    def initialize(period: "day", date: Time.zone.today)
      @period = period
      @date = date
    end

    def fetch_stats
      result = repository.monthly_rolling_window_locations_added(date:) || {}

      {
        count: result[:total] || 0,
        run_time: result[:run_time] || date.to_s,
        metric_name: "service-report-locations-added-rolling-count",
        period:,
        date: date.to_s,
      }
    end

  private

    def repository
      Performance::Repository::Location
    end

    attr_reader :period, :date
  end
end
