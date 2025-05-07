describe "Search Locations", type: :feature do
  let(:user) { create(:user, :with_organisation) }
  let(:organisation) { user.organisations.first }

  context "10 locations with the same name, 1 different and alphabetically last" do
    before :each do
      create_list(:location, 20, postcode: "AA11AA", organisation:) do |location, i|
        location.address = "Aardvark Place #{i}"
        location.ips.new(address: "89.1.1.#{i}")
      end
      create(:location, address: "Zebra Place 0", postcode: "ZZ99ZZ", organisation:, ips: [Ip.new(address: "89.1.1.30"),
                                                                                           Ip.new(address: "89.1.1.31")])
      sign_in_user user
      visit ips_path
    end

    it "Does not filter anything if presented with a blank string" do
      fill_in "search", with: " "
      click_button("Search")
      expect(page).to have_content("AA11AA", minimum: 10)
      expect(page).not_to have_content("ZZ99ZZ")
    end

    it "Filters on postcodes that are not in the current page" do
      fill_in "search", with: "Z99Z"
      expect {
        click_button("Search")
      }.to change {
        page.has_content?("ZZ99ZZ")
      }.from(false).to(true)
    end

    it "Filters on addresses that are not in the current page" do
      fill_in "search", with: "Zebra"
      expect {
        click_button("Search")
      }.to change {
        page.has_content?("ZZ99ZZ")
      }.from(false).to(true)
    end

    it "It shows location address when searching by IP" do
      fill_in "search", with: "Zebr"
      click_button("Search")
      expect(page).to have_content("Zebra Place 0")
      expect(page).to have_content("89.1.1.30 Available at 6am tomorrow", count: 1)
      expect(page).to have_content("89.1.1.31 Available at 6am tomorrow", count: 1)
    end
  end
end
