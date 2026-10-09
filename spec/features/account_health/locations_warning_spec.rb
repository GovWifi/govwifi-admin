describe "Account health warning on Locations", type: :feature do
  include AccountHealthHelpers

  let(:organisation) { create(:organisation) }
  let(:administrator) { add_member(organisation) }
  let(:warning) { find_by_id("account-health-locations") }

  before { allow_account_health_organisation_names }

  context "when an IP-linked location has no address or postcode" do
    let!(:incomplete) { add_location_with_ip(organisation, address: "", postcode: "") }
    let!(:complete) { add_location_with_ip(organisation, address: "2 Complete Street") }

    it "links to the incomplete location for someone who can manage locations" do
      sign_in_user administrator
      visit ips_path

      expect(warning).to have_content("Your organisation has a location without an address or postcode.")
      expect(warning).to have_link("Add the missing details", href: edit_location_path(incomplete))
    end

    it "hides the warning while a confirmation is showing" do
      sign_in_user administrator
      visit ips_path(location_id: complete.id, confirm_remove: true)

      expect(page).to have_content("Are you sure you want to remove this location?")
      expect(page).not_to have_css("#account-health-locations")
    end

    it "does not offer edit links to view-only members" do
      viewer = add_member(organisation, permissions: :view_only)
      sign_in_user viewer
      visit ips_path

      expect(warning).to have_content("Your organisation has a location without an address or postcode.")
      expect(warning).not_to have_link(href: edit_location_path(incomplete))
      expect(warning).to have_content("Ask an administrator or someone who can manage locations to update it.")
    end
  end
end
