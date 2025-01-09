describe Organisation do
  it { is_expected.to have_many(:users).through(:memberships) }
  it { is_expected.to have_many(:locations) }

  describe "#latest_signed_mou_version" do
    let(:user) { create(:user, organisations: [organisation]) }
    let(:organisation) { create(:organisation) }

    it "returns 0 if there is no mou version" do
      expect(organisation.latest_signed_mou_version).to eq BigDecimal("0")
    end
    it "returns the latest signed mou version number" do
      create(:mou, user:, organisation:, version: "1.1")
      create(:mou, user:, organisation:, version: "1.3")
      create(:mou, user:, organisation:, version: "2.1")
      expect(organisation.latest_signed_mou_version).to eq BigDecimal("2.1")
    end
  end

  context "when deleting an organisation" do
    let(:user) { create(:user, organisations: [organisation]) }
    let(:organisation) { create(:organisation, :with_location_and_ip) }
    let(:location) { organisation.locations.first }
    let!(:ip) { location.ips.first }

    before do
      sign_in_user user
    end

    before { organisation.destroy }

    it "removes all associated locations" do
      expect { location.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    it "removes all associated ip addresses" do
      expect { ip.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    it "removes all associated memberships" do
      expect(Membership.find_by(organisation_id: organisation.id)).to be_nil
    end
  end

  context "when name already exists" do
    before { create(:organisation, name: "Gov Org 1") }

    it "is not valid" do
      organisation = build(:organisation, name: "Gov Org 1")
      expect(organisation).not_to be_valid
    end
  end

  context "when an organisation name is in the register" do
    it "is valid" do
      organisation = build(:organisation, name: "Gov Org 1")
      expect(organisation).to be_valid
    end
  end

  context "when an organisation name is not in the register" do
    let(:organisation) { build(:organisation, name: "Some invalid organisation name") }

    it "is not valid" do
      expect(organisation).not_to be_valid
    end

    it "explains why it is invalid" do
      organisation.valid?
      expect(organisation.errors.full_messages).to eq([
        "Name isn't in the organisations allow list",
      ])
    end
  end

  context "when organisation name is left blank" do
    let(:organisation) { build(:organisation, name: "") }

    it "is not valid" do
      expect(organisation).not_to be_valid
    end

    it "explains why it is invalid" do
      organisation.valid?
      expect(organisation.errors.full_messages).to match_array([
        "Name can't be blank", "Name isn't in the organisations allow list"
      ])
    end
  end

  context "when organisation service email is left blank" do
    let(:organisation) { build(:organisation, service_email: "") }

    it "is not valid" do
      expect(organisation).not_to be_valid
    end

    it "displays the appropriate design system error message" do
      organisation.valid?
      expect(organisation.errors.full_messages).to eq([
        "Service email must be in the correct format, like name@example.com",
      ])
    end
  end

  context "when organisation service email is not an email address" do
    let(:organisation) { build(:organisation, service_email: "IncorrectFormat") }

    it "is not valid" do
      expect(organisation).not_to be_valid
    end

    it "displays the appropriate design system error message" do
      organisation.valid?
      expect(organisation.errors.full_messages).to eq([
        "Service email must be in the correct format, like name@example.com",
      ])
    end
  end

  describe "sortable_with_child_counts scope" do
    subject(:sorted_results) { described_class.sortable_with_child_counts(sort_column, sort_direction) }

    let(:first_organisation) { create(:organisation, name: "An org", created_at: 1.day.ago) }
    let(:second_organisation) { create(:organisation, name: "This org", created_at: 2.days.ago) }
    let(:first_location) { create(:location, organisation: first_organisation) }
    let(:second_location) { create(:location, organisation: second_organisation) }
    let(:third_location) { create(:location, organisation: second_organisation) }
    let(:first_ip) { create(:ip, location: first_location) }
    let(:second_ip) { create(:ip, location: first_location) }
    let(:third_ip) { create(:ip, location: second_location) }
    let(:mou) { create(:mou, location: first_organisation.id, created_at: 1.day.ago) }
    let(:mou) { create(:mou, organisation_id: second_organisation.id, created_at: Time.zone.now) }

    before do
      allow(described_class).to receive(:fetch_organisations_from_register)
        .and_return(["An org", "This org"])

      first_location.ips = [first_ip, second_ip]
      second_location.ips << third_ip

      first_organisation.locations << first_location
      second_organisation.locations = [second_location, third_location]
    end

    context "when sorting by name" do
      let(:sort_column) { "name" }
      let(:sort_direction) { "asc" }

      it "orders results alphabetically" do
        expect(sorted_results).to eq([first_organisation, second_organisation])
      end
    end

    context "when sorting by created_at" do
      let(:sort_column) { "created_at" }
      let(:sort_direction) { "asc" }

      it "orders results by date" do
        expect(sorted_results).to eq([second_organisation, first_organisation])
      end
    end

    context "when sorting by signed mou" do
      let(:sort_column) { "latest_mou_created_at" }
      let(:sort_direction) { "asc" }

      it "orders results by date mou was signed" do
        expect(sorted_results).to eq([first_organisation, second_organisation])
      end
    end

    context "when sorting by locations_count" do
      let(:sort_column) { "locations_count" }
      let(:sort_direction) { "asc" }

      it "orders results by number of locations" do
        expect(sorted_results).to eq([first_organisation, second_organisation])
      end
    end

    context "when sorting by ips_count" do
      let(:sort_column) { "ips_count" }
      let(:sort_direction) { "asc" }

      it "orders results by number of ips" do
        expect(sorted_results).to eq([second_organisation, first_organisation])
      end
    end

    context "when sorting in descending order" do
      let(:sort_column) { "locations_count" }
      let(:sort_direction) { "desc" }

      it "orders results in descending order" do
        expect(sorted_results).to eq([second_organisation, first_organisation])
      end
    end
  end

  describe ".all_as_csv" do
    subject(:csv) { CSV.parse(described_class.all_as_csv, headers: true) }

    let(:org1) { create(:organisation) }
    let(:org2) { create(:organisation) }
    let(:location1) { create(:location, organisation: org1) }
    let(:location2) { create(:location, organisation: org1) }
    let(:location3) { create(:location, organisation: org2) }
    let(:ip1) { create(:ip, location: location1) }
    let(:ip2) { create(:ip, location: location1) }
    let(:ip3) { create(:ip, location: location1) }
    let(:ip4) { create(:ip, location: location2) }
    let(:ip5) { create(:ip, location: location3) }

    before do
      ip1
      ip2
      ip3
      ip4
      ip5
    end

    it "exports organisation names" do
      expect(csv.first["Name"]).to eq(org1.name)
    end

    it "exports organisation created dates" do
      expect(csv.first["Created At"]).to eq(org1.created_at.to_s)
    end

    it "exports location counts" do
      expect(csv.first["Locations"]).to eq("2")
    end

    it "exports IP counts" do
      expect(csv.first["IPs"]).to eq("4")
    end
  end

  describe ".service_emails_as_csv" do
    subject(:csv) { CSV.parse(described_class.service_emails_as_csv, headers: true) }

    let(:org1) { create(:organisation) }
    let(:org2) { create(:organisation) }
    let(:user1) { create(:user, email: org1.service_email) }
    let(:user2) { create(:user, email: org2.service_email) }

    before do
      user1
      user2
    end

    it "exports service email addresses for each organisation" do
      expect(csv.first["Service email address"]).to eq(org1.service_email)
    end

    it "exports organisation names" do
      expect(csv.first["Org name"]).to eq(org1.name)
    end

    it "exports the service admin user name" do
      expect(csv.first["User name"]).to eq(user1.name)
    end

    it "exports the organisation created date" do
      expect(csv.first["Created at"]).to eq(org1.created_at.to_s)
    end
  end
end
