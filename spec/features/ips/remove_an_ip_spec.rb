describe 'Removing an IP', type: :feature do
  let(:organisation) { create(:organisation) }
  let(:user) { create(:user, organisations: [organisation]) }
  let(:location) { create(:location, organisation: organisation) }
  let!(:ip) { create(:ip, location: location) }

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
        expect(page).to have_button("Yes, remove this IP")
      end
    end

    it "removes the IP" do
      expect { click_on "Yes, remove this IP" }.to change(Ip, :count).by(-1)
    end

    it "displays the success message to the user" do
      click_on "Yes, remove this IP"
      expect(page).to have_content("Successfully removed IP address #{ip.address}")
    end

    it 'redirects to the "after IP removed" path for Analytics' do
      click_on "Yes, remove this IP"
      expect(page).to have_current_path('/ips/removed')
    end
  end

  context "with incorrect permissions" do
    before do
      user.membership_for(organisation).update!(can_manage_locations: false)
    end

    it "does not show the remove button" do
      visit ips_path

      within("#ips-table") do
        expect(page).not_to have_content("Remove")
      end
    end

    context "when visiting the remove IP page directly" do
      before do
        visit ip_remove_path(ip)
      end

      it "does not show the partial" do
        expect(page).not_to have_content("Are you sure you want to remove this IP")
      end
    end
  end

  context "when you do not own the IP" do
    let(:other_ip) { create(:ip, location: create(:location)) }

    before do
      visit ip_remove_path(other_ip)
    end

    it "does not show the partial" do
      expect(page).not_to have_content("Are you sure you want to remove this IP")
    end
  end
end
