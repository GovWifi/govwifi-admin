describe Gateways::Sessions do
  subject(:session_gateway) { described_class.new }

  let(:today_date) { Time.zone.now.to_s }
  let(:yesterday) { (Time.zone.now - 1.day).to_s }
  let(:two_days_ago) { (Time.zone.now - 2.days).to_s }
  let(:three_weeks_ago) { (Time.zone.now - 3.weeks).to_s }
  let(:username) { "BOBABC" }
  let(:task_id) { "arn:12345" }

  context "when searching by username" do
    let!(:other_sessions) { create_list(:session, 2, username: "AAAAAA") }
    let!(:session_list) do
      [
        create(:session, start: two_days_ago, username:, ap: "ap3"),
        create(:session, start: yesterday, username:, ap: "ap2"),
        create(:session, start: today_date, username:, ap: "ap1"),
      ]
    end

    it "does not find a result result" do
      results = session_gateway.search(username: "NONONO")
      expect(results).to be_empty
    end

    it "finds multiple results" do
      expect(session_gateway.search(username: "BOBABC")).to match_array(session_list)
    end

    it "orders the list with the newest logs first" do
      result = session_gateway.search(username:).map { |r| r[:ap] }
      expect(result).to eq(%w[ap1 ap2 ap3])
    end
  end

  context "when searching by IP address" do
    before do
      ["127.0.0.1", "127.0.0.2", "3.3.3.3"].each do |ip|
        create(:session, username:, siteIP: ip)
      end
    end

    it "finds logs for a particular IP" do
      result = session_gateway.search(ips: "127.0.0.1")
      expect(result.count).to eq(1)
    end

    it "finds logs for any of my organisation IPs" do
      result = session_gateway.search(ips: ["127.0.0.1", "127.0.0.2"])
      expect(result.count).to eq(2)
    end

    it "doesn't allow searching by another organisations IP" do
      result = session_gateway.search(ips: "4.4.4.4")
      expect(result).to be_empty
    end
  end

  context "when searching for logs older than two weeks" do
    before do
      create(:session, start: three_weeks_ago, username: "FOOBAR")
    end

    it "returns no results" do
      expect(session_gateway.search(username: "FOOBAR")).to be_empty
    end
  end
end
