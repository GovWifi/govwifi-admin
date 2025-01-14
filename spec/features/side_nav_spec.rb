describe "Side nav logic", type: :feature do
  before do
    sign_in_user user
    visit root_path
    @section = page.find(".leftnav")
  end

  describe "Highlight links" do
    let(:user) { create(:user, :super_admin, :with_organisation) }
    it "highlights each link in the side bar when clicked" do
      links = @section.all(:link).map(&:text)
      links.each do |link|
        click_on link
        within(".leftnav") do
          expect(page).to have_css("a.active", text: link, exact_text: true)
        end
      end
    end
  end

  describe "Showing link in the side bar" do
    context "Super User" do
      context "With an organisation" do
        let(:user) { create(:user, :super_admin, :with_organisation) }
        it "displays the regular admin links" do
          expect(@section).to have_link("Team members", href: memberships_path)
        end
        it "displays a settings link referring to the new organisation settings path" do
          expect(@section).to have_link("Settings", href: new_organisation_settings_path)
        end
        context "the current organisation contains a location with an ip" do
          let(:user) { create(:user, :confirm_all_memberships, :super_admin, organisations: [create(:organisation, :with_location_and_ip)]) }
          it "displays a settings link referring to the  settings path" do
            expect(@section).to have_link("Settings", href: settings_path)
          end
        end
        it "displays super admin links" do
          expect(@section).to have_link("All Locations")
        end
        it "displays a separation bar" do
          expect(@section).to have_selector("hr.govuk-section-break")
        end
      end
      context "Without an organisation" do
        let(:user) { create(:user, :super_admin) }

        it "does not display the regular admin links" do
          expect(@section).to_not have_link("Team members", href: memberships_path)
        end
        it "displays super admin links" do
          expect(@section).to have_link("All Locations")
        end
        it "does not display a separation bar" do
          expect(@section).to_not have_selector("hr.govuk-section-break")
        end
      end
    end
    context "Regular User" do
      let(:user) { create(:user, :with_organisation) }
      it "displays the regular admin links" do
        expect(@section).to have_link("Team members", href: memberships_path)
      end
      it "does not display super admin links" do
        expect(@section).to_not have_link("All Locations")
      end
      it "does not display a separation bar" do
        expect(@section).to_not have_selector("hr.govuk-section-break")
      end
    end
  end
end
