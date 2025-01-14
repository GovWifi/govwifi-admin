describe "Lookup wifi user contact details", type: :feature do
  include EmailHelpers
  let(:user) { create(:user, :super_admin) }
  let(:search_term) { "" }
  let(:contact) { "wifi.user@govwifi.org" }

  before do
    create(:wifi_user, username: "zZyYxX", contact:)

    sign_in_user user
    visit root_path
    click_on "User Details"

    fill_in "Username, email address or phone number", with: search_term
    click_on "Find user details"
  end

  context "with no search term" do
    it "presents an error message" do
      expect(page).to have_content("Search term can't be blank").twice
    end
  end

  context "with a username search term" do
    let(:search_term) { "ZZYYXX" }

    it "presents the end user contact details" do
      expect(page).to have_content("wifi.user@govwifi.org")
    end

    describe "click on the username link" do
      it "shows a page with logs for the user" do
        click_on "zZyYxX"
        expect(page).to have_content("We have no record of username \"zZyYxX\" reaching the GovWifi service from your organisation in the last 2 weeks")
      end
    end
  end

  context "with an unknown username" do
    let(:search_term) { "AAAAAA" }

    it "presents the end user contact details" do
      expect(page).to have_content("Nothing found for 'AAAAAA'")
    end
  end

  context "with a phone number search term" do
    let(:search_term) { "+447891234567" }
    let(:contact) { "+447891234567" }

    it "presents the end user username" do
      expect(page).to have_content("zZyYxX")
    end
  end

  context "with an email address search term" do
    let(:search_term) { "wifi.user@govwifi.org" }

    it "presents the end user username" do
      expect(page).to have_content("zZyYxX")
    end
  end

  context "when deleting a user" do
    let(:search_term) { "zZyYxX" }
    it "successfully deletes the user" do
      click_on "Remove user"

      expect(page).to have_content("Confirm removing #{contact}")

      click_on "Remove user"

      expect(page).to have_content("#{search_term} (#{contact}) has been removed")

      expect(WifiUser.search(search_term)).to be_nil
    end
  end
end
