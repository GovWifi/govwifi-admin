describe "Filter CBA requests for an IP", type: :feature do
  let(:ip_address) { "11.22.33.44" }
  let(:ip) { create(:ip, address: ip_address) }
  let(:username) { "ABCDEF" }
  let(:ap) { "govwifi-ap" }
  let(:mac) { "govwifi-mac" }
  let(:time) { 3.days.ago }
  let(:task_id) { "arn:12345" }

  before do
    create(:session,
           ap:,
           mac:,
           start: time,
           username: nil,
           siteIP: ip.address,
           success: true,
           cert_name: "test",
           task_id:)

    create(:session,
           ap:,
           mac:,
           start: time,
           username:,
           siteIP: ip.address,
           task_id:)
  end

  context "as a super admin" do
    before do
      organisation = create(:organisation, cba_enabled: true)
      super_admin_user = create(:user, :confirm_all_memberships, :super_admin, organisations: [organisation])
      sign_in_user super_admin_user
      visit logs_path(log_search_form: { ip: ip.address, filter_option: LogSearchForm::IP_FILTER_OPTION })
    end

    it "displays the log" do
      expect(page).to have_content("Found 2 results for IP: \"#{ip.address}\"")
    end

    context "when filtering for all requests" do
      before do
        select("All", from: "Authentication method")
        click_button("Filter")
      end

      it "shows all requests" do
        expect(page).to have_css("td", text: "EAP-TLS")
        expect(page).to have_css("td", text: "MSCHAP")
      end

      it "keeps the selection on 'All'" do
        expect(page).to have_select("Authentication method", selected: "All")
      end
    end

    context "when fitering for EAP-TLS requests" do
      before do
        select("EAP-TLS", from: "Authentication method")
        click_button("Filter")
      end

      it "shows only EAP-TLS requests" do
        expect(page).to have_css("td", text: "EAP-TLS")
        expect(page).to_not have_css("td", text: "MSCHAP")
      end

      it "keeps the selection on 'EAP-TLS'" do
        expect(page).to have_select("Authentication method", selected: "EAP-TLS")
      end
    end

    context "when filtering for MSCHAP requests" do
      before do
        select("MSCHAP", from: "Authentication method")
        click_button("Filter")
      end

      it "shows only MSCHAP requests" do
        expect(page).to have_css("td", text: "MSCHAP")
        expect(page).to_not have_css("td", text: "EAP-TLS")
      end

      it "keeps the selection on 'MSCHAP'" do
        expect(page).to have_select("Authentication method", selected: "MSCHAP")
      end
    end

    context "when filtering for successful and EAP-TLS requests" do
      before do
        select("Successful", from: "Status type")
        select("EAP-TLS", from: "Authentication method")
        click_button("Filter")
      end

      it "shows successful requests" do
        expect(page).to have_css("td", text: "successful")
        expect(page).to_not have_css("td", text: "failed")
      end

      it "shows MSCHAP requests" do
        expect(page).to have_css("td", text: "EAP-TLS")
        expect(page).to_not have_css("td", text: "MSCHAP")
      end

      it "keeps the selection on 'EAP-TLS'" do
        expect(page).to have_select("Authentication method", selected: "EAP-TLS")
      end

      it "keeps the selection on 'Successful'" do
        expect(page).to have_select("Status type", selected: "Successful")
      end
    end
  end
end
