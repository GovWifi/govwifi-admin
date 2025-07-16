describe UseCases::NewLocations do
  before do
    Timecop.freeze(Time.zone.local(2025, 5, 22))

    create(:location, created_at: Time.zone.today)
    create(:location, created_at: 2.days.ago)
    create(:location, created_at: 20.days.ago)

    @date = Time.zone.today
  end

  it "displays the correct data" do
    expect(described_class.fetch_stats).to eq(
      {
        metric: "new_locations",
        date: Time.zone.today,
        daily_new_locations: 1,
        weekly_new_locations: 2,
        monthly_new_locations: 3,
      },
    )
  end
end
