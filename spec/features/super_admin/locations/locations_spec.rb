describe "View and search locations", type: :feature do
  let(:user) { create(:user, :super_admin) }
  let(:organisation) { create(:organisation) }

  before do
    create(:location, address: "69 Garry Street, London", postcode: "HA7 2BL", organisation:)
    sign_in_user user
    visit root_path
    within(".leftnav") { click_on "All Locations" }
  end

  it "takes the user to the locations page" do
    expect(page).to have_content("GovWifi locations")
  end

  context "with all the locations details" do
    it "lists the full address of the location" do
      expect(page).to have_content("69 Garry Street, London, HA7 2BL")
    end

    it "lists the organisation the location belongs to" do
      expect(page).to have_content(organisation.name)
    end

    it "does not show the pager because there is only one page" do
      expect(page).to_not have_css(".pager__controls")
    end
  end

  context "select an organisation with 41 locations" do
    before :each do
      FactoryBot.create_list(:location, 40, organisation:)
      click_on organisation.name
    end
    it "shows 5 pages, a 'Next' link but not a 'Previous' link" do
      expect(page).to_not have_content "Previous"
      expect(page).to have_content(/1\s*2\s*3\s*4\s*5\s*Next/).twice
    end
    it "shows 5 pages, a 'Next' link and a 'Previous' link" do
      within(".govuk-pagination", match: :first) { click_on "3" }
      expect(page).to have_content(/Previous page\s*1\s*2\s*3\s*4\s*5\s*Next page/).twice
    end
    it "shows 5 pages, a 'Previous' link but not a 'Next' link" do
      within(".govuk-pagination", match: :first) { click_on "5" }
      expect(page).to_not have_content "Next"
      expect(page).to have_content(/Previous page\s*1\s*2\s*3\s*4\s*5/).twice
    end
  end

  context "selecting a location" do
    before do
      create(:user, name: "Team member 1", organisations: [organisation], last_sign_in_at: "10 Dec 2023", email: "adam@gov.uk")
      create(:user, name: "Team member 2", organisations: [organisation], last_sign_in_at: "10 Feb 2011", email: "brian@gov.uk")
      create(:user, name: "Team member 3", organisations: [organisation], last_sign_in_at: "10 Dec 2013", email: "Toni@gov.uk")

      click_on "69 Garry Street, London, HA7 2BL"
    end

    it "takes the user to the organisation page" do
      expect(page).to have_content(organisation.name)
    end

    it "shows the team section" do
      expect(page).to have_content("Team")
    end

    it "shows the last login for the team" do
      expect(page).to have_content("Last login")
    end

    it "shows the login count for the team members" do
      expect(page).to have_content("Logins")
    end

    it "the list is sorted from newest to oldest, after Last login is clicked the first time" do
      click_link "Last login"
      expect(page.body).to match(/Team member 1.*Team member 3.*Team member 2/m)
    end

    it "the list is sorted from oldest to newest, after Last login is clicked again" do
      2.times { click_link "Last login" }

      expect(page.body).to match(/Team member 2.*Team member 3.*Team member 1/m)
    end

    it "the list is sorted after Email is clicked the first time" do
      click_link "Email"

      expect(page.body).to match(/Team member 3.*Team member 2.*Team member 1/m)
    end

    it "the list is sorted in reverse order after Email is clicked again" do
      2.times { click_link "Email" }

      expect(page.body).to match(/Team member 1.*Team member 2.*Team member 3/m)
    end

    it "the list is sorted after Username is clicked the first time" do
      click_link "Username"

      expect(page.body).to match(/Team member 3.*Team member 2.*Team member 1/m)
    end

    it "the list is sorted in reverse order after Username is clicked again" do
      2.times { click_link "Username" }

      expect(page.body).to match(/Team member 1.*Team member 2.*Team member 3/m)
    end
  end
end
