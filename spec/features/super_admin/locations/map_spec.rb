describe "GovWifi locations map", type: :feature do
  let!(:location) { create(:location, postcode: "SE10HS") }

  before do
    stub_request(:post, "https://api.postcodes.io/postcodes")
      .to_return(status: 200, body: { 'result': [] }.to_json)
    user = create(:user, :super_admin)
    sign_in_user user
    visit map_super_admin_locations_path
  end

  it "shows a map of locations" do
    expect(page).to have_content("GovWifi Map of Locations")
    assert_requested :post, "https://api.postcodes.io/postcodes", body: "postcodes%5B%5D=SE10HS"
  end

  it "allows Google Maps to load on this page" do
    csp = page.response_headers["Content-Security-Policy"]
    expect(csp).to include("script-src 'self' https://maps.googleapis.com")
    expect(csp).to include("https://*.gstatic.com")
    expect(csp).to match(/style-src 'self' 'unsafe-inline' https:\/\/fonts.googleapis.com;/)
  end

  it "takes the super admin back to the locations page" do
    click_link "Back to locations"
    expect(page).to have_content(location.address)
  end
end
