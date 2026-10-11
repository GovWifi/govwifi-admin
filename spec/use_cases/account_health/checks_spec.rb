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

  describe "fewer than two administrators" do
    it "applies to organisations with fewer than two administrators who have accepted their invitation" do
      no_admins = create(:organisation)
      one_admin = create(:organisation).tap { |org| add_member(org) && add_member(org, accepted: false) }
      create(:organisation).tap { |org| 2.times { add_member(org) } }

      expect(described_class.new.organisation_ids(:fewer_than_two_administrators)).to eq([no_admins.id, one_admin.id])
    end
  end

  describe "inactive administrators" do
    it "applies to organisations with an administrator who has not signed in for over a year" do
      inactive = create(:organisation).tap { |org| add_member(org) && add_member(org, signed_in_at: 2.years.ago) }
      create(:organisation).tap { |org| add_member(org) && add_member(org, signed_in_at: nil) }

      expect(described_class.new.organisation_ids(:inactive_administrator)).to eq([inactive.id])
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
