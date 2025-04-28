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

  it "does not show the organisation that the user is not part of in the dropdown" do
    expect(page).not_to have_select "Select an organisation", options: [organisation_1.name], selected: organisation.name
  end

  it "only renders the organisations the user is part of" do
    expect(page).to have_select "Select an organisation", options: [organisation.name], selected: organisation.name
  end
end
