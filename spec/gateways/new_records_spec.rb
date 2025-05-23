describe Gateways::NewRecords do
  subject(:gateway) { described_class.new(model) }
  describe "when searching new records for organisations" do
    let(:model) { Organisation }

    before do
      create(:organisation, created_at: Time.zone.today)
      create(:organisation, created_at: 5.days.ago)
      create(:organisation, created_at: 10.days.ago)
    end

    it "fetches daily count" do
      expect(gateway.fetch_daily_count).to eq(1)
    end

    it "fetches weekly count" do
      expect(gateway.fetch_weekly_count).to eq(2)
    end

    it "fetches monthly count" do
      expect(gateway.fetch_monthly_count).to eq(3)
    end
  end

  describe "when searching new records for locations" do
    let(:model) { Location }

    before do
      create(:location, created_at: Time.zone.today)
      create(:location, created_at: 5.days.ago)
      create(:location, created_at: 10.days.ago)
    end

    it "fetches daily count" do
      expect(gateway.fetch_daily_count).to eq(1)
    end

    it "fetches weekly count" do
      expect(gateway.fetch_weekly_count).to eq(2)
    end

    it "fetches monthly count" do
      expect(gateway.fetch_monthly_count).to eq(3)
    end
  end
end
