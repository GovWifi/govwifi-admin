module Gateways
  class NewOrganisations
    def fetch_daily_new_organisations
      Organisation
        .where("created_at >= ?", 1.day.ago)
        .count
    end

    def fetch_weekly_new_organisations
      Organisation
        .where("created_at >= ?", 1.week.ago)
        .count
    end

    def fetch_monthly_new_organisations
      Organisation
        .where("created_at >= ?", 1.month.ago)
        .count
    end
  end
end
