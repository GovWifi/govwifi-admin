describe "View a list of signed up organisations", type: :feature do
  context "when not logged in" do
    before do
      visit super_admin_organisations_path
    end

    it_behaves_like "not signed in"
  end

  context "when logged in as a normal user" do
    let(:user) { create(:user, :with_organisation) }

    before do
      sign_in_user user
      visit super_admin_organisations_path
    end

    it_behaves_like "shows the settings page"
  end

  context "when logged in as an admin" do
    let(:user) { create(:user, :super_admin) }

    before do
      sign_in_user user
      visit super_admin_organisations_path
    end

    context "when one organisation exists" do
      let(:cba_enabled) { true }
      let(:organisation) { create(:organisation, created_at: "1 Feb 2014", cba_enabled:) }

      before do
        create_list(:location, 2, organisation:)
        create_list(:ip, 3, location: Location.first)
        visit super_admin_organisations_path
      end

      it "shows their name" do
        within("table") do
          expect(page).to have_content "Org 1"
        end
      end

      it "shows when they signed up" do
        within("table") do
          expect(page).to have_content("1 Feb 2014")
        end
      end

      it "shows they have 10 locations" do
        within("table") do
          expect(page).to have_content("2")
        end
      end

      it "shows they have 11 IPs" do
        within("table") do
          expect(page).to have_content("3")
        end
      end

      it "shows a link to download as CSV" do
        expect(page).to have_link("Download all organisations in CSV format")
      end

      it "shows a link to download service emails as CSV" do
        expect(page).to have_link("Download all service emails in CSV format")
      end

      describe "no certificates" do
        it "shows the organisation does not use EAP-TLS" do
          within("table tbody tr td:nth-child(6)") do
            expect(page).to have_content("no")
          end
        end
      end
      describe "a certificate is present" do
        let(:organisation) { create(:organisation, cba_enabled:).tap { |org| create(:certificate, organisation: org) } }
        it "shows the organisation uses EAP-TLS" do
          within("table tbody tr td:nth-child(6)") do
            expect(page).to have_content("yes")
          end
        end
      end
    end

    context "with multiple organisations with multiple locations each" do
      before do
        2.times do
          organisation = create(:organisation)
          create_list(:location, 3, organisation:)
        end

        visit super_admin_organisations_path
      end

      it "summarises the totals" do
        expect(page).to have_content(
          "GovWifi is in 6 locations across 2 organisations.",
        )
      end

      it "shows all three organisations" do
        Organisation.all.find_each do |org|
          expect(page).to have_content(org.name)
        end
      end

      it "allows sorting organisations by name" do
        org1 = create(:organisation, created_at: 3.days.ago)
        org2 = create(:organisation, created_at: 1.day.ago)

        visit super_admin_organisations_path

        within("table tbody") do
          expect(page.text).to match(/#{org1.name}.*#{org2.name}/)
        end

        click_link "Name"

        within("table tbody") do
          expect(page.text).to match(/#{org2.name}.*#{org1.name}/)
        end
      end
    end
  end
end
