describe "Update location", type: :feature do
  let(:organisation) { create(:organisation, locations: [location]) }
  let(:user) { create(:user, :confirm_all_memberships, organisations: [organisation]) }
  let(:location) { create(:location) }

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

  context "update current location details" do
    let(:new_address) { "new address" }
    let(:new_postcode) { "E14 4BU" }
    it "succeeds" do
      fill_in "Address", with: new_address
      fill_in "Postcode", with: new_postcode
      click_on "Update"
      location.reload
      expect(location.address).to eq(new_address)
      expect(location.postcode).to eq(new_postcode)
    end
  end
end
