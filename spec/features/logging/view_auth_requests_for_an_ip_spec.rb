describe "View authentication requests for an IP", type: :feature do
  before do
    sign_in_user user
  end

  context "User has an organisation, with a location and an IP" do
    let(:ip_address) { ip.address }
    let(:ip) { create(:ip) }
    let(:location) { create(:location, ips: [ip]) }
    let(:organisation) { create(:organisation, locations: [location], cba_enabled: true) }
    let(:user) { create(:user, :confirm_all_memberships, organisations: [organisation]) }

    before do
      create(:session, siteIP: ip_address, username: "Aaaaaa", cert_name: "EAP-TLS")
    end
    describe "when using a link" do
      before do
        visit ips_path
        within(:xpath, "//tr[th[normalize-space(text())=\"#{ip_address}\"]]") do
          click_on "View logs"
        end
      end
      it "displays the authentication requests" do
        expect(page).to have_content("Found 1 result for IP: \"#{ip_address}\"")
      end

      context "when the organisations is using CBA" do
        it "displays the certificate data" do
          expect(page).to have_content("EAP-TLS")
        end
      end
    end

    context "when searching for an IP address" do
      before do
        visit new_logs_search_path
        choose "IP address"
        fill_in "Enter an IP address associated within your organisation", with: search_string
        click_on "Show logs"
      end

      context "with a correct IP" do
        let(:search_string) { ip_address }

        it "displays the authentication requests" do
          expect(page).to have_content("Found 1 result for IP: \"#{ip_address}\"")
        end

        it "displays address associated with the IP" do
          expect(page).to have_content("IP address #{ip_address} is located at #{location.address}, #{location.postcode}")
        end

        it "has hyperlinks for username" do
          click_on "Aaaaaa"
          expect(page).to have_content("for username: \"Aaaaaa\"")
        end
      end
    end

    context "with an IP that is not part of the current organisation" do
      let(:other_ip) { other_org.locations.first.ips.first.address }
      let(:other_org) { create(:organisation, :with_location_and_ip) }
      before do
        create(:session, siteIP: other_ip, username: "BBBBBB")
        visit new_logs_search_path
        choose "IP address"
        fill_in "Enter an IP address associated within your organisation", with: other_ip
        click_on "Show logs"
      end
      context "as a regular admin" do
        it "shows there are no results" do
          expect(page).to have_content("This is not an IP address associated with your organisation")
        end
      end
      context "as a super admin" do
        let(:user) { create(:user, :super_admin) }

        it "finds log entries for ip addresses regardless of the current organisation" do
          expect(page).to have_content("Found 1 result for IP: \"#{other_ip}\"")
        end
      end
    end

    context "with an incorrect IP" do
      let(:search_string) { "1" }
      before do
        visit new_logs_search_path
        choose "IP address"
        fill_in "Enter an IP address associated within your organisation", with: search_string
        click_on "Show logs"
      end

      it_behaves_like "errors in form"

      it "displays an error summary" do
        expect(page).to have_content("Enter an IP address in the correct format").twice
      end
    end
  end
end
