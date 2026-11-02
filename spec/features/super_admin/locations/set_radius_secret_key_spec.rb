describe "Set Radius Secret Key", type: :feature do
  let(:user) { create(:user, :super_admin) }
  let(:organisation) { create(:organisation) }
  let(:location) { create(:location, address: "London", postcode: "HA7 2BL", organisation:) }

  before do
    location.radius_secret_key = "0123456789"
    location.save!
    sign_in_user user
    visit root_path
    click_on "All Locations"
    click_on location.address
    click_on "Set secret key"
  end

  it "shows the form to edit the secret key" do
    expect(page).to have_content("Set Radius secret key for London")
  end

  it "shows the radius secret key" do
    expect(page).to have_field("location[radius_secret_key]", with: "0123456789")
  end

  it "updates the radius secret key" do
    fill_in "Radius secret key", with: "ABCDEFGHIKJ"
    expect { click_on "Update" }.to change { location.reload.radius_secret_key }.from("0123456789").to("ABCDEFGHIKJ")
  end

  it "reports the secret key is too short" do
    fill_in "Radius secret key", with: "ABCD"
    click_on "Update"
    expect(page).to have_content("The secret key is too short (minimum is 10 characters)").twice
  end

  it "redirects back to the super admin locations page" do
    fill_in "Radius secret key", with: "ABCDEFGHIKJ"
    click_on "Update"
    expect(page).to have_current_path(super_admin_locations_path)
  end
end
