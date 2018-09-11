describe Gateways::Ips do
  let(:location_1) { create(:location, organisation: create(:organisation)) }
  let(:location_2) { create(:location, organisation: create(:organisation)) }
  let(:result) { Ip.all }

  before do
    create(:ip, address: "127.0.0.1", location: location_1)
    create(:ip, address: "186.3.1.1", location: location_2)
  end

  it "fetches the locations_ips" do
    expect(subject.fetch_ips).to eq(result)
  end
end
