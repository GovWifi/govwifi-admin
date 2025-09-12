describe "View whether IPs are ready", type: :feature do
  context "when one IP has been added" do
    let(:user) { create(:user, :with_organisation) }
    let!(:another_administrator) { create(:user, organisations: [user.organisations.first]) }
    let!(:location) { create(:location, organisation: user.organisations.first) }

    before do
      sign_in_user user
      visit location_add_ips_path(location_id: location.id)
      fill_in "location_ips_form[ip_1]", with: "141.0.149.130"
      click_on "Add IP addresses"
    end

    context "when viewing the new IP immediately" do
      before { visit ips_path }

      it "shows it is activating tomorrow" do
        expect(page).to have_content("Available at 6am tomorrow")
      end
    end

    context "when viewing the IP after a day" do
      before do
        Ip.all.find_each do |ip|
          ip.update(created_at: Date.yesterday)
        end
        sign_in_user user
        visit ips_path
      end

      it "shows it as available" do
        expect(page).to have_content("No traffic received")
      end

      it "does not shpow any IPs as available tomorrow" do
        expect(page).not_to have_content("tomorrow")
      end
    end
  end
end
