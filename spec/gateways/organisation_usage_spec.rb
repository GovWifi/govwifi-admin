describe Gateways::Sessions do
  subject(:session) { described_class }

  def create_data(differences)
    differences = [differences] unless differences.is_a? Array
    org = create(:organisation, created_at: Time.zone.local(2014, 7, 3, 20, 3, 0))
    loc = create(:location, organisation: org)
    differences.each do |difference|
      create(:ip, created_at: Time.zone.local(2014, 7, 3 + difference, 20, 3, 0), location: loc)
    end
  end

  describe "when there is no data" do
    it "returns nothing" do
      expect(session.organisation_usage_stats).to eq(0)
    end
  end

  describe "when there is data" do
    before do
      create_data(1)
    end

    it "includes one set of data" do
      expect(session.organisation_usage_stats).to eq(1)
    end
  end

  describe "when there are mutiple organisations and ips" do
    it "calculates the median of an even number of values" do
      create_data(1)
      create_data(3)
      expect(session.organisation_usage_stats).to eq(2)
    end
    it "calculates the median of an odd number of values" do
      create_data(1)
      create_data(3)
      create_data(7)
      expect(session.organisation_usage_stats).to eq(3)
    end
  end

  describe "many ip addresses" do
    it "only uses the IP address that was created first" do
      create_data([5, 2, 6, 9, 3])
      expect(session.organisation_usage_stats).to eq(2)
    end
  end

  describe "many organisations and many IP addresses" do
    it "calculates the median value of of the difference between the organisation creation date and the first IP address" do
      create_data([5, 1, 6, 9, 3])
      create_data([3, 2, 7, 2])
      create_data([4, 6, 9, 8, 8, 9])
      expect(session.organisation_usage_stats).to eq(2)
    end
  end
end
