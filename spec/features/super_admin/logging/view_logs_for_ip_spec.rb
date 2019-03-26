describe 'View authentication requests for an IP', type: :feature do
  let(:user) { create(:user) }
  let(:user_location) { create(:location, organisation: user.organisation) }
  let(:ip_1) { create(:ip, location: user_location, address: '1.2.3.4') }

  let(:user_2) { create(:user) }
  let(:user_2_location) { create(:location, organisation: user_2.organisation) }
  let(:ip_2) { create(:ip, location: user_2_location, address: '1.2.3.5') }

  let(:super_admin) { create(:user, super_admin: true) }

  before do
    Session.create!(
      start: 3.days.ago,
      siteIP: ip_1.address,
    )

    Session.create!(
      start: 3.days.ago,
      siteIP: ip_1.address,
    )

    Session.create!(
      start: 3.days.ago,
      siteIP: ip_2.address,
    )

    Session.create!(
      start: 3.days.ago,
      siteIP: ip_2.address,
    )

    sign_in_user super_admin
    visit ip_new_logs_search_path
  end

  context "when searching for an IP" do
    before do
      fill_in "IP address", with: ip_1.address
      click_on "Show logs"
    end

    it 'displays all found results for that searched IP' do
      expect(page).to have_content("Found 2 results for \"#{ip_1.address}\"")
    end
  end

  context "when searching for another IP" do
    before do
      fill_in "IP address", with: ip_2.address
      click_on "Show logs"
    end

    it 'displays all found results for that searched IP' do
      expect(page).to have_content("Found 2 results for \"#{ip_2.address}\"")
    end
  end

  context "with an incorrect IP" do
    let(:search_string) { "1" }

    before do
      fill_in "IP address", with: search_string
      click_on "Show logs"
    end

    it_behaves_like "errors in form"

    it "displays an error summary" do
      expect(page).to have_content("Search term must be a valid IP address")
    end
  end
end
