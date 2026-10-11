describe UseCases::AccountHealth::Checks do
  include AccountHealthHelpers

  before { allow_account_health_organisation_names }

  describe "no signed MoU" do
    it "applies to organisations with no MoU record" do
      unsigned = create(:organisation)
      create(:mou, organisation: create(:organisation))

      expect(described_class.new.organisation_ids(:no_signed_mou)).to eq([unsigned.id])
    end
  end

  describe "missing location details" do
    let(:organisation) { create(:organisation) }

    it "flags locations with IP addresses that have neither an address nor a postcode" do
      incomplete = add_location_with_ip(organisation, address: "", postcode: "unknown")
      add_location_with_ip(organisation, address: "2 High Street", postcode: "")
      create(:location, organisation:).update_columns(address: nil, postcode: "")

      checks = described_class.new
      expect(checks.organisation_ids(:missing_location_details)).to eq([organisation.id])
      expect(checks.incomplete_locations).to eq([incomplete])
    end
  end
end
