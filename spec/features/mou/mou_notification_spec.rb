describe "MOU notification banner", type: :feature do
  let(:user) { create(:user, :with_organisation) }
  let(:organisation) { user.organisations.first }

  before do
    sign_in_user user
  end

  context "when organisation needs to sign the MOU" do
    it "shows the notification banner with sign the MOU link" do
      visit settings_path

      expect(page).to have_css(".govuk-notification-banner")
      expect(page).to have_content("Your organisation hasn’t signed the MOU yet.")
      expect(page).to have_link("Sign the memorandum of understanding", href: show_options_mous_path)
    end
  end

  context "when organisation does not need to sign the MOU" do
    before do
      organisation.mous.destroy_all
      create(:mou, organisation: organisation, version: Mou.latest_known_version)
      visit settings_path
    end
    it "does not show the notification banner" do
      expect(page).not_to have_css(".govuk-notification-banner")
      expect(page).not_to have_content("Your organisation hasn’t signed the MOU yet.")
    end
  end
end
