describe "View authentication requests for an IP", type: :feature do
  let(:ip) { "1.2.3.4" }
  let(:username) { "ABCDEF" }
  let(:ap) { "govwifi-ap" }
  let(:mac) { "govwifi-mac" }
  let(:time) { 3.days.ago }
  let(:task_id) { "arn:12345" }

  before do
    create(:session,
           ap: ap,
           mac: mac,
           start: time,
           username: username,
           siteIP: ip,
           success: true,
           task_id: task_id)
  end

  context "as a super admin" do
    before do
      super_admin_user = create(:user, :with_organisation, :super_admin)
      sign_in_user super_admin_user
      visit logs_path(ip: ip)
    end
    it "displays the log" do
      expect(page).to have_content("Found 1 result for \"#{ip}\"")
      expect(page).to have_css("td", text: username)
      expect(page).to have_css("td", text: ap)
      expect(page).to have_css("td", text: mac)
      expect(page).to have_css("td", text: ip)
      expect(page).to have_css("td", text: time)
      expect(page).to have_css("td", text: "successful")
    end
    it "displays the radius server" do
      expect(page).to have_css("th", text: "Radius Server")
      expect(page).to have_css("td", text: task_id)
    end
  end
  context "as a regular admin" do
    before do
      admin_user = create(:user, :with_organisation)
      location = create(:location, organisation: admin_user.organisations.first)
      create(:ip, location_id: location.id, address: ip, created_at: 5.days.ago)
      sign_in_user admin_user
      visit logs_path(ip: ip)
    end
    it "does not display the radius server" do
      expect(page).to have_content("Found 1 result for \"#{ip}\"")
      expect(page).to_not have_css("td", text: task_id)
      expect(page).to_not have_css("th", text: "Radius Server")
    end
  end
end