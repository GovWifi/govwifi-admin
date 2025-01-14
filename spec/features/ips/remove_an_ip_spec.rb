describe "Removing an IP", type: :feature do
  let(:user) { create(:user, :confirm_all_memberships, organisations: [organisation]) }
  let(:organisation) { create(:organisation, locations: [location]) }
  let(:location) { create(:location, ips: [ip]) }
  let(:ip) { create(:ip) }

  before do
    sign_in_user user
  end

  context "with correct permissions" do
    before do
      visit ips_path
      click_on "Remove"
    end

    it "shows the remove IP partial" do
      within(".govuk-error-summary") do
        expect(page).to have_content(ip.address)
      end
    end

    it "shows the remove IP button" do
      within(".govuk-error-summary") do
        expect(page).to have_button("Remove")
      end
    end

    it "removes the IP" do
      within(".govuk-error-summary") do
        expect { click_on "Remove" }.to change(Ip, :count).by(-1)
      end
    end

    it "displays the success message to the user" do
      within(".govuk-error-summary") do
        click_on "Remove"
      end

      expect(page).to have_content("Successfully removed IP address #{ip.address}")
    end

    it 'redirects to the "after IP removed" path for Analytics' do
      within(".govuk-error-summary") do
        click_on "Remove"
      end

      expect(page).to have_current_path("/ips")
    end
  end

  context "with incorrect permissions" do
    before do
      user.membership_for(organisation).update!(can_manage_locations: false)
    end

    it "does not show the remove button" do
      visit ips_path
      within(:xpath, "//tr[th[normalize-space(text())=\"#{ip.address}\"]]") do
        expect(page).not_to have_content("Remove")
      end
    end

    context "when visiting the remove IP page directly" do
      before do
        visit ips_path(ip_id: ip.id, confirm_remove: true)
      end

      it "does not show the partial" do
        expect(page).not_to have_content("Are you sure you want to remove this IP")
      end
    end
  end

  context "when you do not own the IP" do
    let(:other_ip) { create(:ip, :with_location) }

    before do
      visit ips_path(ip: ip.id, confirm_remove: true)
    end

    it "does not show the partial" do
      expect(page).not_to have_content("Are you sure you want to remove this IP")
    end
  end
end
