describe "View authentication requests for an IP", type: :feature do
  let(:ip_address) { "11.22.33.44" }
  let(:ip) { create(:ip, address: ip_address) }
  let(:username) { "ABCDEF" }
  let(:access_point) { "govwifi-ap" }
  let(:mac) { "govwifi-mac" }
  let(:time) { 3.days.ago }
  let(:task_id) { "arn:12345" }

  before do
    create(:session,
           ap: access_point,
           mac:,
           start: time,
           username:,
           siteIP: ip.address,
           success: true,
           task_id:)

    create(:session,
           ap: access_point,
           mac:,
           start: time,
           username:,
           siteIP: ip.address,
           success: false,
           task_id:)
  end

  context "as a super admin" do
    before do
      super_admin_user = create(:user, :super_admin, :with_organisation)
      sign_in_user super_admin_user
      visit logs_path(log_search_form: { ip: ip.address, filter_option: LogSearchForm::IP_FILTER_OPTION })
    end
    it "displays the log" do
      expect(page).to have_content("Found 2 results for IP: \"#{ip.address}\"")
      expect(page).to have_css("td", text: username)
      expect(page).to have_css("td", text: access_point)
      expect(page).to have_css("td", text: mac)
      expect(page).to have_css("td", text: time.to_fs(:no_timezone))
      expect(page).to have_css("td", text: "successful")
      expect(page).to have_css("td", text: "failed")
    end
    it "displays the radius server" do
      expect(page).to have_css("th", text: "Radius Server")
      expect(page).to have_css("td", text: task_id)
    end

    context "when filtering for all requests" do
      before do
        select("All", from: "Status type")
        click_button("Filter")
      end

      it "shows all requests" do
        expect(page).to have_css("td", text: "successful")
        expect(page).to have_css("td", text: "failed")
      end

      it "keeps the selection on 'All'" do
        expect(page).to have_select("Status type", selected: "All")
      end
    end

    context "when fitering for successful requests" do
      before do
        select("Successful", from: "Status type")
        click_button("Filter")
      end

      it "shows only successful requests" do
        expect(page).to have_css("td", text: "successful")
        expect(page).to_not have_css("td", text: "failed")
      end

      it "keeps the selection on 'Successful'" do
        expect(page).to have_select("Status type", selected: "Successful")
      end
    end

    context "when filtering for failed requests" do
      before do
        select("Failed", from: "Status type")
        click_button("Filter")
      end

      it "shows only failed requests" do
        expect(page).to_not have_css("td", text: "successful")
        expect(page).to have_css("td", text: "failed")
      end

      it "keeps the selection on 'Failed'" do
        expect(page).to have_select("Status type", selected: "Failed")
      end
    end
  end

  context "as a regular admin" do
    let(:ip) { create(:ip, location_id: location.id, address: ip_address, created_at: 5.days.ago) }
    let(:admin_user) { create(:user, :with_organisation) }
    let(:location) { create(:location, organisation: admin_user.organisations.first) }

    before do
      sign_in_user admin_user
      visit logs_path(log_search_form: { ip: ip.address, filter_option: LogSearchForm::IP_FILTER_OPTION })
    end
    it "does not display the radius server" do
      expect(page).to have_content("Found 2 results for IP: \"#{ip.address}\"")
      expect(page).to_not have_css("td", text: task_id)
      expect(page).to_not have_css("th", text: "Radius Server")
    end
  end
end
