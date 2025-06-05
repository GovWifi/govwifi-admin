describe "Choosing how to filter", type: :feature do
  let(:user) do
    create(:user, :with_organisation)
  end
  before do
    sign_in_user user
  end
  context "as a regular admin" do
    context "with no filter chosen" do
      before do
        visit new_logs_search_path
        click_on "Show logs"
      end

      it_behaves_like "errors in form"
    end

    context "when changing URL parameters" do
      context "with no filter on results link" do
        before { visit logs_path }

        it "redirects me to choosing a filter" do
          expect(page).to have_content("How do you want to filter these logs?")
        end
      end
    end
  end

  context "A super admin without a current organisation" do
    let(:user) { create(:user, :super_admin) }
    before do
      visit new_logs_search_path
    end

    it "shows the option to filter by user name" do
      within(".govuk-radios") do
        expect(page).to have_content("Username")
      end
    end

    it "shows the option to filter by IP address" do
      within(".govuk-radios") do
        expect(page).to have_content("IP address")
      end
    end

    it "does not show the option to filter by Location" do
      within(".govuk-radios") do
        expect(page).to_not have_content("Location")
      end
    end

    it "does show the option to filter MAC address" do
      within(".govuk-radios") do
        expect(page).to have_content("MAC address")
      end
    end
  end

  context "A user with a current organisation" do
    let(:user) { create(:user, :with_organisation) }
    before do
      visit new_logs_search_path
    end
    it "shows the option to filter by user name" do
      within(".govuk-radios") do
        expect(page).to have_content("Username")
      end
    end

    it "shows the option to filter by IP address" do
      within(".govuk-radios") do
        expect(page).to have_content("IP address")
      end
    end

    context "The current organisation has no locations" do
      it "shows the option to filter by Location" do
        within(".govuk-radios") do
          expect(page).not_to have_content("Location")
        end
      end
    end
    context "The current organisation does have locations" do
      let(:user) do
        create(:user, :with_organisation_and_locations)
      end
      it "shows the option to filter by Location" do
        within(".govuk-radios") do
          expect(page).to have_content("Location")
        end
      end
    end
  end
end
