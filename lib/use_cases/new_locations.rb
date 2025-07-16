class UseCases::NewLocations
  def self.fetch_stats
    gateway = Gateways::NewRecords.new(Location)

    {
      metric: "new_locations",
      date: Time.zone.today,
      daily_new_locations: gateway.fetch_daily_count,
      weekly_new_locations: gateway.fetch_weekly_count,
      monthly_new_locations: gateway.fetch_monthly_count,
    }
  end
end
