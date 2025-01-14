describe "View authentication requests for a username", type: :feature do
  let(:admin_user) { create(:user, :confirm_all_memberships, organisations: [organisation_one, organisation_two]) }
  let(:organisation_one) { create(:organisation, :with_location_and_ip) }
  let(:organisation_two) { create(:organisation, :with_location_and_ip) }
  let(:ip_organisation_one) { organisation_one.ip_addresses.first }
  let(:ip_organisation_two) { organisation_two.ip_addresses.first }
  let(:other_ip) { "6.6.6.6" }
  let!(:sessions) do
    create(:session, username: "AAAAAA", siteIP: ip_organisation_one, success: true)
    create(:session, username: "AAAAAA", siteIP: ip_organisation_one, success: false)
    create(:session, username: "AAAAAA", siteIP: ip_organisation_two, success: true)
    create(:session, username: "BBBBBB", siteIP: other_ip, success: false)
  end

  before :each do
    sign_in_user admin_user
    visit new_logs_search_path
    choose "Username"
    fill_in "Enter username", with: search_string
    click_on "Show logs"
  end

  describe "without results" do
    describe "Searching a username that does not belong to the current organisation" do
      let(:search_string) { "BBBBBB" }

      it "displays no results" do
        expect(page).to have_content("We have no record of username \"#{search_string}\" reaching the GovWifi service from your organisation in the last 2 weeks")
      end
    end

    describe "Searching a username that does not exist" do
      let(:search_string) { "random" }

      it "displays the no results message" do
        expect(page).to have_content("We have no record of username \"#{search_string}\" reaching the GovWifi service from your organisation in the last 2 weeks")
      end
    end
  end

  describe "With results" do
    context "Super admin" do
      let!(:admin_user) { create(:user, :super_admin, :with_organisation) }
      describe "Searching a username that does not belong to the current organisation" do
        let(:search_string) { "BBBBBB" }

        it "finds the session even though it is not part of the current organisation." do
          expect(page).to have_content("Found 1 result for username: \"#{search_string}\"")
        end
      end
    end

    describe "Searching a username that does belong to the current organisation" do
      let(:search_string) { "AAAAAA" }

      it "displays two results" do
        expect(page).to have_content("Found 2 results for username: \"#{search_string}\"")
      end

      it "displays a successful request" do
        expect(page).to have_content("successful")
      end

      it "displays a failed request" do
        expect(page).to have_content("failed")
      end

      it "displays the logs of the ip" do
        expect(page).to have_content(ip_organisation_one)
      end

      it "does not display the logs of the ip that does not belong to the current organisation" do
        expect(page).not_to have_content(ip_organisation_two)
        expect(page).not_to have_content(other_ip)
      end
    end

    describe "The search input has trailing whitespace" do
      let(:search_string) { "AAAAAA " }

      it "displays the search results of the username" do
        expect(page).to have_content(ip_organisation_one)
      end
    end

    describe "The search input has leading whitespace" do
      let(:search_string) { " AAAAAA" }

      it "displays the search results of the username" do
        expect(page).to have_content(ip_organisation_one)
      end
    end

    describe "The username is too short" do
      let(:search_string) { "1" }

      it_behaves_like "errors in form"

      it "displays an error to the user" do
        expect(page).to have_content("Search term must be 5 or 6 characters").twice
      end
    end

    describe "when clicking on the ip address hyperlink" do
      let(:search_string) { "AAAAAA" }
      it "goes to ip logs page" do
        click_link ip_organisation_one, match: :first
        expect(page).to have_content("for IP: \"#{ip_organisation_one}\"")
      end
    end
  end
end
