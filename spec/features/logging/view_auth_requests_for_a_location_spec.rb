describe "View authentication requests for a location", type: :feature do
  let(:user) { create(:user, :confirm_all_memberships, organisations: [organisation]) }

  before do
    sign_in_user user
    visit new_logs_search_path
    choose "Location"
  end

  context "when selecting a location to view logs for" do
    let!(:locations) do
      [build(:location, address: "Abbey Street", postcode: "HA7 2BL"),
       build(:location, address: "Zeon Grove", postcode: "HA7 3BL"),
       build(:location, address: "Garry Road", postcode: "HA7 4BL")]
    end
    let!(:organisation) { create(:organisation, locations:) }

    it "shows the organisations in alphabetical order" do
      location_options = find("#log-search-form-location-id-field").all("option").map(&:text)
      expect(location_options).to match_array ["Abbey Street, HA7 2BL", "Garry Road, HA7 4BL", "Zeon Grove, HA7 3BL"]
    end
  end

  context "when choosing a location without log entries" do
    let!(:organisation) { create(:organisation, :with_locations) }
    let(:location) { organisation.locations.first }

    before do
      select location.address, from: "Select location"
      click_on "Show logs"
    end

    it "displays the no results message" do
      expect(page).to have_content("Traffic from #{location.address} is not reaching the GovWifi service")
    end
  end

  context "with a location that does not belong to the current organisation" do
    let!(:organisation) { create(:organisation, locations: [build(:location)]) }
    let(:location) { create(:location) }

    it "should raise an error" do
      expect {
        visit logs_path(log_search_form: { location_id: location.id,
                                           filter_option: LogSearchForm::LOCATION_FILTER_OPTION })
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "when choosing a location with logs" do
    let(:organisation) { create(:organisation, :with_location_and_ip) }
    let(:ip_address) { organisation.locations.first.ips.first.address }
    let!(:sessions) do
      create(:session, username: "AAAAAA", siteIP: ip_address, success: true)
      create(:session, username: "BBBBBB", siteIP: "6.6.6.6", success: false)
    end

    before do
      select organisation.locations.first.address, from: "Select location"
      click_on "Show logs"
    end

    it "displays logs for IPs under that location" do
      expect(page).to have_content(ip_address)
    end

    it "does not display logs for other IPs" do
      expect(page).not_to have_content("6.6.6.6")
    end

    it "has hyperlinks for username" do
      click_on "AAAAAA"
      expect(page).to have_content("for username: \"AAAAAA\"")
    end

    it "has hyperlinks for IP address" do
      click_on ip_address
      expect(page).to have_content("for IP: \"#{ip_address}\"")
    end

    context "when fitering for successful requests" do
      before do
        select("Successful", from: "Status type")
        click_button("Filter")
      end

      it "shows only successful requests" do
        expect(page).to have_content("successful")
        expect(page).to_not have_content("failed")
      end
    end

    context "when filtering for failed requests" do
      before do
        select("Failed", from: "Status type")
        click_button("Filter")
      end

      it "shows only failed requests" do
        expect(page).to_not have_content("successful")
        expect(page).to have_content("failed")
      end
    end

    context "when going back to search by a different location" do
      let!(:location_two) { create(:location, :with_ip, organisation:) }
      let(:ip_address_two) { location_two.ip_addresses.first }

      before do
        create(:session, username: "AAAAAA", siteIP: ip_address_two)
        click_on "Change search"
        choose "Location"
        select location_two.address, from: "Select location"
        click_on "Show logs"
      end

      it "displays logs for IPs under that location" do
        expect(page).to have_content(ip_address_two)
      end

      it "does not display logs for other IPs" do
        expect(page).not_to have_content(ip_address)
      end
    end
  end
end
