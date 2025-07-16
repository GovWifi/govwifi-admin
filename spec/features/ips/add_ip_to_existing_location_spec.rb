describe "Adding an IP to an existing location", type: :feature do
  let(:user) { create(:user, :with_organisation) }
  let(:location) { create(:location, organisation: user.organisations.first) }
  let!(:another_administrator) { create(:user, organisations: [user.organisations.first]) }
  let!(:mou) { create(:mou, organisation: user.organisations.first, version: Mou.latest_known_version) }

  context "when viewing the form" do
    before do
      sign_in_user user
      visit location_add_ips_path(location_id: location.id)
    end

    it "shows no error summary" do
      page.assert_no_selector(".govuk-error-summary")
    end

    it "shows no individual errors" do
      page.assert_no_selector(".govuk-error-message")
    end
  end

  context "when entering an IP address" do
    before do
      sign_in_user user
      visit location_add_ips_path(location_id: location.id)
      fill_in "location_ips_form[ip_1]", with: ip_address
      click_on "Add IP addresses"
    end

    context "with valid data" do
      let(:ip_address) { "141.0.149.130" }

      it "adds the IP" do
        within(".flash-message-notice") do
          expect(page).to have_content("Added 1 IP address to #{location.full_address}")
        end
      end

      it "adds to the correct location" do
        expect(location.reload.ips.map(&:address)).to include("141.0.149.130")
      end

      it 'redirects to the "after IP created" path for Analytics' do
        expect(page).to have_current_path("/ips")
      end

      it "triggers the publishing of the config file" do
        expect(Gateways::S3.new(**Gateways::S3::RADIUS_IPS_ALLOW_LIST).read).to include(ip_address)
        expect(Gateways::S3.new(**Gateways::S3::LOCATION_IPS).read).to include(ip_address)
      end
    end

    context "with invalid data" do
      let(:ip_address) { "10.wrong.0.1" }

      it "shows a error message" do
        expect(page).to have_content("'10.wrong.0.1' is not a valid IP address")
      end

      it "does not add an IP to the location" do
        expect(location.reload.ips).to be_empty
      end
    end

    context "with data as an IPv6 address" do
      let(:ip_address) { "FE80::0202:B3FF:FE1E:8329" }

      it "does not add an IP to the location" do
        expect(location.reload.ips).to be_empty
      end

      it "shows an error message" do
        within(".govuk-error-message") do
          expect(page).to have_content("'FE80::0202:B3FF:FE1E:8329' is an IPv6 address. Only IPv4 addresses can be added")
        end
      end
    end

    context "with data as a private IP address" do
      let(:ip_address) { "192.168.0.0" }

      it "does not add an IP to the location" do
        expect(location.reload.ips).to be_empty
      end

      it "shows an error message" do
        within(".govuk-error-message") do
          expect(page).to have_content("'192.168.0.0' is a private IP address. Only public IPv4 addresses can be added.")
        end
      end
    end

    context "with blank data" do
      let(:ip_address) { "" }

      it "does not add an IP to the location" do
        expect(location.reload.ips).to be_empty
      end

      it "shows an error message" do
        expect(page).to have_content("Enter at least one IP address")
      end
    end
  end

  context "when selecting another location" do
    let(:other_location) do
      create(:location, organisation: user.organisations.first)
    end

    before do
      sign_in_user user
      visit location_add_ips_path(location_id: other_location.id)
      fill_in "location_ips_form[ip_1]", with: "141.0.149.130"
      click_on "Add IP addresses"
    end

    it "adds the IP" do
      within(".flash-message-notice") do
        expect(page).to have_content("Added 1 IP address to #{other_location.full_address}")
      end
    end

    it "adds to that location" do
      expect(other_location.reload.ips.map(&:address)).to include("141.0.149.130")
    end

    it 'redirects to the "after IP created" path for Analytics' do
      expect(page).to have_current_path("/ips")
    end
  end

  context "when adding multiple IP addresses" do
    before do
      sign_in_user user
      visit location_add_ips_path(location_id: location.id)
      ip_addresses.each.with_index(1) do |ip, index|
        fill_in "location_ips_form[ip_#{index}]", with: ip
      end
      click_on "Add IP addresses"
    end

    context "when filling in all 5 boxes" do
      let(:ip_addresses) do
        ["123.0.0.1", "123.0.0.2", "123.0.0.3", "123.0.0.4", "123.0.0.5"]
      end

      it "shows a success message" do
        within(".flash-message-notice") do
          expect(page).to have_content("Added 5 IP addresses to #{location.full_address}")
        end
      end

      it "shows the added IP addresses" do
        ip_addresses.each do |ip_address|
          expect(page).to have_content(ip_address)
        end
      end
    end

    context "when filling entering non-consecutive boxes" do
      let(:ip_addresses) do
        ["123.0.1.1", "", "123.0.1.2", "", "123.0.1.3"]
      end

      it "adds the IP addresses" do
        within(".flash-message-notice") do
          expect(page).to have_content("Added 3 IP addresses to #{location.full_address}")
        end
      end

      it "shows the added IP addresses" do
        [
          "123.0.1.1", "123.0.1.2", "123.0.1.3"
        ].each do |ip_address|
          expect(page).to have_content(ip_address)
        end
      end
    end

    context "with IP addresses already in use" do
      let(:ip_addresses) do
        ["123.0.0.2", "123.0.0.10"]
      end

      it "adds the IP addresses" do
        within(".flash-message-notice") do
          expect(page).to have_content("Added 2 IP addresses to #{location.full_address}")
        end
      end
    end
  end

  context "when not logged in" do
    before do
      visit location_add_ips_path(location_id: location.id)
    end

    it_behaves_like "not signed in"
  end

  context "when there is only one administrator for the organisation" do
    before do
      user.organisations.first.users.delete(another_administrator)
      sign_in_user user
      visit location_add_ips_path(location_id: location.id)
    end

    it "shows error summary" do
      expect(page).to have_content("There is a problem\nYou must add another administrator before you can add IPs or multiple locations.")
    end
  end

  context "when the organisation has not signed the MoU" do
    before do
      user.organisations.first.mous.destroy_all
    end

    it "redirects to IPs page with an alert" do
      sign_in_user user
      visit location_add_ips_path(location_id: location.id)

      expect(page).to have_current_path(ips_path)
      expect(page).to have_content("Your organisation must sign the Memorandum of Understanding (MoU) before you can add IPs or multiple locations.")
    end
  end
end
