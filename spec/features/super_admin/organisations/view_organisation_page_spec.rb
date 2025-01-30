describe "View details of an organisation", type: :feature do
  let(:organisation) { create(:organisation) }

  context "when there are lots of pages so that pagy renders a 'gap'" do
    it "renders a gap" do
      100.times { organisation.locations << create(:location, organisation:) }
      sign_in_user create(:user, :super_admin)
      visit super_admin_organisation_path(organisation)
      expect(page.body).to include(Pagy::I18n.translate(nil, "pagy.gap"))
    end
  end

  context "when logged in as a super-admin" do
    let!(:location_1) { create(:location, organisation:, address: "Aarry Street") }
    let!(:location_2) { create(:location, organisation:, address: "Carry Street") }
    let!(:location_3) { create(:location, organisation:, address: "Barry Lane") }

    let!(:user_1) { create(:user, name: "Aardvark", organisations: [organisation]) }
    let!(:user_2) { create(:user, name: "Zed", organisations: [organisation]) }
    let!(:user_3) { create(:user, name: "Dave", email: "batman@batcave.com", organisations: [organisation]) }

    before do
      create(:user, organisations: [organisation])
      sign_in_user create(:user, :super_admin)
      visit super_admin_organisation_path(organisation)
    end

    it "does not render a gap" do
      expect(page.body).to_not include(Pagy::I18n.translate(nil, "pagy.nav.gap"))
    end

    it "shows details page for the organisations" do
      expect(page).to have_content(organisation.name)
    end

    it "has the creation date of the organisation" do
      expect(page).to have_content(
        organisation.created_at.strftime(
          "#{organisation.created_at.day.ordinalize} of %B, %Y",
        ),
      )
    end

    it "has a Usage section" do
      expect(page).to have_content("Usage")
    end

    it "shows the number of users" do
      within("#user-count") do
        expect(page).to have_content("4")
      end
    end

    it "lists the users" do
      organisation.users.each do |user|
        expect(page).to have_content(user.name)
      end
    end

    it "lists all team members in alphabetical order" do
      expect(page.body).to match(/#{user_1.name}.*#{user_3.name}.*#{user_2.email}/m)
    end

    it "shows the number of locations" do
      within("#location-count") do
        expect(page).to have_content("3")
      end
    end

    it "lists all locations in alphabetical order" do
      expect(page.body).to match(/#{location_1.address}.*#{location_3.address}.*#{location_2.address}/m)
    end

    context "without IPs" do
      it "shows the number of IPs" do
        within("#ip-count") do
          expect(page).to have_content("0")
        end
      end
    end

    context "with IPs" do
      let!(:ip_1) { create(:ip, location: location_1) }
      let!(:ip_2) { create(:ip, location: location_2) }
      let!(:ip_3) { create(:ip, location: location_3) }

      before do
        visit super_admin_organisation_path(organisation)
      end

      it "shows the number of IPs" do
        within("#ip-count") do
          expect(page).to have_content("3")
        end
      end

      it "shows an IP" do
        expect(page).to have_content(ip_1.address)
        expect(page).to have_content(ip_2.address)
        expect(page).to have_content(ip_3.address)
      end
    end

    it "has a service email" do
      expect(page).to have_content(organisation.service_email)
    end
  end

  context "when logged out" do
    before { visit super_admin_organisation_path(organisation) }

    it_behaves_like "not signed in"
  end

  context "when logged in as a normal user" do
    before do
      sign_in_user create(:user, :with_organisation)
      visit super_admin_organisation_path(organisation)
    end

    it_behaves_like "user not authorised"
  end
end
