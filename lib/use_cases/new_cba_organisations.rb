class UseCases::NewCbaOrganisations
  def self.fetch_stats
    gateway = Gateways::NewRecords.new(Organisation.where(cba_enabled: true))

    {
      metric: "new_cba_organisations",
      date: Time.zone.today,
      daily_new_cba_organisations: gateway.fetch_daily_count,
      weekly_new_cba_organisations: gateway.fetch_weekly_count,
      monthly_new_cba_organisations: gateway.fetch_monthly_count,
    }
  end
end
