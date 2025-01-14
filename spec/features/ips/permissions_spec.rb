describe "Add an IP", type: :feature do
  let(:organisation) { create(:organisation) }
  let(:user) { create(:user, :confirm_all_memberships, organisations: [organisation]) }

  before do
    sign_in_user user
  end

  context "with .can_manage_locations permission" do
    before do
      user.membership_for(organisation).update!(can_manage_locations: true)
    end

    it "displays the add new IP link" do
      visit ips_path
      expect(page).to have_link("Add a location")
    end
  end

  context "without .can_manage_locations permission" do
    before do
      user.membership_for(organisation).update!(can_manage_locations: false)
    end

    it "hides the add new IP link" do
      visit ips_path
      expect(page).not_to have_link("Add IP address")
    end

    context "when viewing the homepage instructions" do
      before do
        Ip.delete_all
      end

      it "has a link to add new IP addresses" do
        visit root_path
        expect(page).not_to have_link("add the IPs")
      end
    end
  end
end
