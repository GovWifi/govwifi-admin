describe UseCases::NewOrganisations do
  before do
    Timecop.freeze(Time.zone.local(2025, 5, 22))

    create(:organisation, created_at: Time.zone.today)
    create(:organisation, created_at: 2.days.ago)
    create(:organisation, created_at: 20.days.ago)

    @date = Time.zone.today
  end

  it "displays the correct data" do
    expect(described_class.fetch_stats).to eq(
      {
        metric: "new_organisations",
        date: Time.zone.today,
        daily_new_organisations: 1,
        weekly_new_organisations: 2,
        monthly_new_organisations: 3,
      },
    )
  end
end
