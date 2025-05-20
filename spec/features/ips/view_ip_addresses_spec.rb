describe "Viewing IP addresses", type: :feature do
  let(:user) { create(:user, :with_organisation) }

  def xpath_row_containing_ip(ip)
    "//div[@class=\"govuk-summary-list__row\"][.//dt[text()=\"#{ip.address}\"]]"
  end

  context "with no IPs" do
    before do
      sign_in_user user
    end

    it "shows no IPs" do
      visit ips_path
      expect(page).to have_content "You need to add at least one location to offer GovWifi"
    end

    context "when visiting the root path" do
      before do
        visit root_path
      end

      it_behaves_like "shows the settings page"
    end
  end

  context "with IPs" do
    let(:location) { create(:location, organisation: user.organisations.first) }
    let!(:ip) { create(:ip, location:, created_at: 9.days.ago) }
    before do
      sign_in_user user
      visit ips_path
    end

    it "shows the RADIUS secret key" do
      expect(page).to have_content(location.radius_secret_key)
    end

    it "shows the IP" do
      expect(page).to have_content(ip.address)
    end

    it "shows the locations address" do
      expect(page).to have_content(location.address)
    end

    context "with inactive IPs" do
      before do
        create(:session, start: (Time.zone.today - 11.days), username: "abc123", siteIP: ip.address)
        visit ips_path
      end

      it "labels the IP as inactive" do
        within(:xpath, xpath_row_containing_ip(ip)) do
          expect(page).to have_content("No traffic in the last 10 days")
        end
      end

      it "does not show success rate" do
        expect(page).to_not have_content("success rate")
      end
    end

    context "with newly created IPs with no activity" do
      it "labels the IP as created but unused" do
        within(:xpath, xpath_row_containing_ip(ip)) do
          expect(page).to have_content("No traffic received")
        end
      end
    end

    context "with active IPs" do
      before do
        create(:session, start: Time.zone.today, username: "abc123", siteIP: ip.address)
        visit ips_path
      end

      it "Does not label the IP as inactive" do
        within(:xpath, xpath_row_containing_ip(ip)) do
          expect(page).not_to have_content("No traffic for the last 10 days")
        end
      end

      it "Does not label the IP as unused" do
        within(:xpath, xpath_row_containing_ip(ip)) do
          expect(page).not_to have_content("No traffic received yet")
        end
      end

      it "shows the success rate" do
        expect(page).to_not have_content("100% success rate")
      end
    end
  end

  context "when logged out" do
    before { visit ips_path }

    it_behaves_like "not signed in"
  end
end
