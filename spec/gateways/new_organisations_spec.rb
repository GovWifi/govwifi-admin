describe Gateways::NewOrganisations do
  subject(:gateway) { described_class.new }

  before do
    create(:organisation, created_at: Time.zone.now)
    create(:organisation, created_at: 5.days.ago)
    create(:organisation, created_at: 8.days.ago)
    create(:organisation, created_at: 14.days.ago)
  end

  describe "fetch daily new organisations" do
    it "returns organisations created today only" do
      expect(gateway.fetch_daily_new_organisations).to eq(1)
    end
  end

  describe "fetch weekly new organisations" do
    it "returns organisations created within this week only" do
      expect(gateway.fetch_weekly_new_organisations).to eq(2)
    end
  end

  describe "fetch monthly new organisations" do
    it "returns organisations created within this month only" do
      expect(gateway.fetch_monthly_new_organisations).to eq(4)
    end
  end
end
