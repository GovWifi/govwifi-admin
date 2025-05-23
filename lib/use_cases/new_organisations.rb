class UseCases::NewOrganisations
  def self.fetch_stats
    gateway = Gateways::NewRecords.new(Organisation)

    {
      metric: "new_organisations",
      date: Time.zone.today,
      daily_new_organisations: gateway.fetch_daily_count,
      weekly_new_organisations: gateway.fetch_weekly_count,
      monthly_new_organisations: gateway.fetch_monthly_count,
    }
  end
end
