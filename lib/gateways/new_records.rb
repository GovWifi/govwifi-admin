module Gateways
  class NewRecords
    def initialize(model)
      @model = model
    end

    def fetch_daily_count
      fetch_count_since(1.day.ago)
    end

    def fetch_weekly_count
      fetch_count_since(1.week.ago)
    end

    def fetch_monthly_count
      fetch_count_since(1.month.ago)
    end

  private

    def fetch_count_since(time)
      @model.where("created_at >= ?", time).count
    end
  end
end
