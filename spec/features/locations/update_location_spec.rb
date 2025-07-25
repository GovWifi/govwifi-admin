describe "Update location", type: :feature do
  let(:location) { create(:location) }
  let(:organisation) { location.organisation }
  let!(:organisation_1) { create(:organisation) }
  let(:user) { create(:user, :confirm_all_memberships, organisations: [organisation]) }

  before do
    sign_in_user user
    visit ips_path
    click_on "Update this location"
  end

  it "displays an instruction to update a location" do
    expect(page).to have_content("Update location")
  end

  it "displays a Cancel link" do
    expect(page).to have_link("Cancel", href: "/ips")
  end

  it "renders organisation select with all organisations" do
    expect(page).to have_select "Select an organisation", options: [organisation.name, organisation_1.name], selected: organisation.name
  end

  context "update current location details" do
    let(:new_address) { "new address" }
    let(:new_postcode) { "E14 4BU" }
    let(:new_organisation) { organisation_1.name }

    it "succeeds" do
      fill_in "Address", with: new_address
      fill_in "Postcode", with: new_postcode
      select(new_organisation, from: "Select an organisation")
      expect(location.organisation.name).to eq(organisation.name)
      click_on "Update"
      location.reload
      expect(location.address).to eq(new_address)
      expect(location.postcode).to eq(new_postcode)
      expect(location.organisation.name).to eq(new_organisation)
    end
  end
end
