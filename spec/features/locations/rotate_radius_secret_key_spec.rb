describe "Rotate RADIUS secret key", type: :feature do
  context "when it is a company that I belong to" do
    let(:user_1) { create(:user, :with_organisation) }
    let!(:location_1) { create(:location, organisation: user_1.organisations.first) }
    let(:radius_key) { "AAAAAAAAAA1111111111" }
    let(:set_secret_key) { location_1.update!(radius_secret_key: radius_key) }

    before do
      location_1.update!(radius_secret_key: radius_key)
      sign_in_user user_1
      visit ips_path
      click_on "Rotate secret key"
      click_on "Yes, rotate this RADIUS key"
    end

    it "will tell the user they have successfully rotated their RADIUS key" do
      expect(page).to have_content("RADIUS secret key has been successfully rotated")
    end

    it "will not show the old RADIUS secret key for that location" do
      expect(page).not_to have_content(radius_key)
    end
    it "will tell the user they have successfully rotated their RADIUS key" do
      expect(page).to have_content("RADIUS secret key has been successfully rotated")
    end

    it "will not show the old RADIUS secret key for that location" do
      expect(page).not_to have_content(radius_key)
    end
  end

  context "when it is a company that I do not belong to" do
    let(:organisation) { create(:organisation) }
    let(:user_2) { create(:user, :confirm_all_memberships, organisations: [organisation]) }
    let(:location_2) { create(:location, organisation: user_2.organisations.first) }

    before do
      user_2.membership_for(organisation).update!(can_manage_locations: false)
      sign_in_user user_2
      visit ips_path
    end

    it "will not show the rotate secret key button" do
      expect(page).not_to have_content("Rotate secret key")
    end
  end
end
