describe UseCases::BackupTeamMembers do
  subject(:use_case) do
    described_class.new(writer:)
  end

  let(:writer) { instance_spy(Gateways::GoogleDrive) }

  let(:test_time) { Time.zone.now }

  let!(:alphabetically_first) do
    org = create(:organisation, name: "Gov Org 1")
    create(:membership, :confirmed, user: create(:user, name: "Ada Lovelace", email: "ada@example.gov.uk"), organisation: org)
    create(:membership, :confirmed, permission_level: "manage_locations", user: create(:user, name: "Belle Bassett", email: "belle@example.gov.uk"), organisation: org)
    org
  end

  let!(:alphabetically_second) do
    org = create(:organisation, name: "Gov Org 2")
    create(:membership, :confirmed, user: create(:user, name: "Grace Hopper", email: "grace@example.gov.uk"), organisation: org)
    # Invited member: name is blank until they accept the invitation.
    create(:membership, :unconfirmed, permission_level: "view_only", user: create(:user, name: "", email: "pending@example.gov.uk", confirmed_at: nil), organisation: org)
    org
  end

  before do
    alphabetically_first
    alphabetically_second

    Deploy.env = "test"
    Timecop.freeze(test_time) { use_case.execute }
  end

  it "writes the generated CSV" do
    expect(writer).to have_received(:write)
      .with(
        file_name: "test-#{test_time.strftime('%Y-%m-%d-%H-%M-%S')}.csv",
        folder_name: "GovWifi Team Members Backup",
        upload_source: be_a(StringIO),
        mime_type: "application/csv",
      )
  end

  it "groups organisations alphabetically by name" do
    rows = read_csv(use_case.execute)
    org_names = rows[1..].map(&:first)
    expect(org_names.uniq).to eq(["Gov Org 1", "Gov Org 2"])
    expect(org_names).to eq(org_names.sort)
  end

  it "emits the expected header" do
    rows = read_csv(use_case.execute)
    expect(rows.first).to eq(UseCases::BackupTeamMembers::TEAM_MEMBER_COLUMNS)
  end

  it "records each confirmed team member with their role and status" do
    rows = read_csv(use_case.execute)
    alpha_rows = rows.select { |r| r.first == "Gov Org 1" }
    expect(alpha_rows).to eq([
      ["Gov Org 1", "Ada Lovelace", "ada@example.gov.uk", "administrator", "confirmed"],
      ["Gov Org 1", "Belle Bassett", "belle@example.gov.uk", "location_manager", "confirmed"],
    ])
  end

  it "records pending members with a blank name, their role and invited status" do
    rows = read_csv(use_case.execute)
    beta_rows = rows.select { |r| r.first == "Gov Org 2" }
    expect(beta_rows).to include(
      ["Gov Org 2", "", "pending@example.gov.uk", "view_only", "invited"],
    )
  end

  it "sorts team members within each organisation by name then email" do
    rows = read_csv(use_case.execute)
    beta_rows = rows.select { |r| r.first == "Gov Org 2" }
    expect(beta_rows.map(&:second)).to eq(["", "Grace Hopper"])
  end

private

  def read_csv(_csv)
    CSV.parse(use_case.build_csv)
  end
end
