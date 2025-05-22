class UseCases::NewOrganisations
  def self.fetch_stats
    gateway = Gateways::NewOrganisations.new

    {
      metric: "new_organisations",
      date: Time.zone.today,
      daily_new_organisations: gateway.fetch_daily_new_organisations,
      weekly_new_organisations: gateway.fetch_weekly_new_organisations,
      monthly_new_organisations: gateway.fetch_monthly_new_organisations,
    }
  end
end
