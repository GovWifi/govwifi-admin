# frozen_string_literal: true

module Performance::UseCase
  class MonthToDateOrganisationsAdded
    def initialize(period: "day", date: Time.zone.today)
      @period = period
      @date = date
    end

    def fetch_stats
      result = repository.month_to_date_organisations_added(date:) || {}

      {
        count: result[:total] || 0,
        run_time: result[:run_time] || date.to_s,
        metric_name: "service-report-organisations-addeded-mtd-count",
        period:,
        date: date.to_s,
      }
    end

  private

    def repository
      Performance::Repository::Organisation
    end

    attr_reader :period, :date
  end
end
