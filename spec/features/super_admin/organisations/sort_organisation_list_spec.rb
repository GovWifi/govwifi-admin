describe "Sorting the organisations list", type: :feature do
  context "as a super admin" do
    let!(:super_admin) { create(:user, :super_admin) }

    before do
      create(:organisation, :with_cba_enabled, name: "Gov Org 1", created_at: "10 Dec 2015")
      create(:organisation, :with_cba_enabled, name: "Gov Org 2", created_at: "10 Dec 2013")
      create(:organisation, :with_cba_enabled, name: "Gov Org 3", created_at: "10 Feb 2014")
      create(:certificate, organisation: Organisation.find_by_name("Gov Org 2"))

      sign_in_user super_admin
      visit super_admin_organisations_path
    end

    context "when using the initial page view" do
      it "the list is sorted by Name, in ascending alphabetic order" do
        expect(page.body).to match(/Gov Org 1.*Gov Org 2.*Gov Org 3/m)
      end
    end

    context "when using account creation date" do
      it "the list is sorted from newest to oldest, after Created on is clicked the first time" do
        click_link "Created on"

        expect(page.body).to match(/Gov Org 1.*Gov Org 3.*Gov Org 2/m)
      end

      it "the list is sorted from oldest to newest, after Created on is clicked again" do
        2.times { click_link "Created on" }

        expect(page.body).to match(/Gov Org 2.*Gov Org 3.*Gov Org 1/m)
      end
    end

    context "when using organisation name" do
      it "the list is sorted from Z-A, after Name is clicked the first time" do
        click_link "Name"

        expect(page.body).to match(/Gov Org 3.*Gov Org 2.*Gov Org 1/m)
      end

      it "the list is sorted from A-Z, after Name is clicked again" do
        2.times { click_link "Name" }

        expect(page.body).to match(/Gov Org 1.*Gov Org 2.*Gov Org 3/m)
      end

      context "when using cba in use" do
        it "sorts the list from yes to no after CBA in use? is clicked the first time" do
          click_link "CBA in use?"

          expect(page.body).to match(/Gov Org 2.*Gov Org 1.*Gov Org 3/m)
        end
        it "sorts the list from no to yes after CBA in use? is clicked twice" do
          2.times { click_link "CBA in use?" }

          expect(page.body).to match(/Gov Org 1.*Gov Org 3.*Gov Org 2/m)
        end
      end

      context "when using cba enabled" do
        before do
          create(:organisation, name: "Local Auth 1", cba_enabled: true)
          create(:organisation, name: "Gov Org 4", cba_enabled: false)
        end

        it "sorts the list from yes to no after CBA enabled? is clicked the first time" do
          click_link "CBA enabled?"

          expect(page.body).to match(/Local Auth 1.*Gov Org 4/m)
        end

        it "sorts the list from no to yes after CBA enabled? is clicked twice" do
          2.times { click_link "CBA enabled?" }

          expect(page.body).to match(/Gov Org 4.*Local Auth 1/m)
        end
      end
    end

    context "when using location count" do
      before do
        create(:location, organisation: Organisation.find_by(name: "Gov Org 1"))
        org3 = Organisation.find_by(name: "Gov Org 3")
        create(:location, organisation: org3)
        create(:location, organisation: org3)
      end

      it "the list is sorted by number of locations descending, after Locations is clicked the first time" do
        within(".govuk-table__head") { click_link "Locations" }

        expect(page.text).to match(/Gov Org 3.*Gov Org 1.*Gov Org 2/)
      end

      it "the list is sorted by number of locations ascending, after Locations is clicked again" do
        within(".govuk-table__head") { 2.times { click_link "Locations" } }

        expect(page.text).to match(/Gov Org 2.*Gov Org 1.*Gov Org 3/)
      end
    end

    context "when using ip count" do
      before do
        location1 = create(:location, organisation: Organisation.find_by(name: "Gov Org 1"))
        org3 = Organisation.find_by(name: "Gov Org 3")
        create(:location, organisation: org3)
        location3 = create(:location, organisation: org3)
        create(:ip, location: location1)
        create(:ip, location: location1)
        create(:ip, location: location3)
      end

      it "the list is sorted by the number of ips descending, after IPs is clicked the first time" do
        within(".govuk-table__head") { click_link "IPs" }

        expect(page.text).to match(/Gov Org 1.*Gov Org 3.*Gov Org 2/)
      end

      it "the list is sorted by the number of ips ascending, after Ips is clicked again" do
        within(".govuk-table__head") { 2.times { click_link "IPs" } }

        expect(page.text).to match(/Gov Org 2.*Gov Org 3.*Gov Org 1/)
      end
    end
  end
end
