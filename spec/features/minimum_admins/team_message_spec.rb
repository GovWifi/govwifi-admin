describe "Team message", type: :feature do
  let(:organisation) { create(:organisation) }

  before do
    users = create_list(:user, number_of_admins, :confirm_all_memberships, organisations: [organisation])
    sign_in_user users.first
  end
  context "there is only one administrator" do
    let(:number_of_admins) { 1 }
    it "shows a message that there should be a minimum of 2 administrators" do
      visit memberships_path
      expect(page).to have_content("There must be a minimum of 2 administrators for each organisation.")
    end
    it "ignores non-administrator level users" do
      create(:membership, :view_only, :confirmed, organisation: organisation, user: create(:user))
      visit memberships_path
      expect(page).to have_content("There must be a minimum of 2 administrators for each organisation.")
    end
    it "ignores unconfirmed users" do
      create(:membership, :administrator, :unconfirmed, organisation: organisation, user: create(:user))
      visit memberships_path
      expect(page).to have_content("There must be a minimum of 2 administrators for each organisation.")
    end
  end
  context "there are two administrators" do
    let(:number_of_admins) { 2 }
    it "does not show a message that there should be a minimum of 2 administrators" do
      visit memberships_path
      expect(page).to_not have_content("There must be a minimum of 2 administrators for each organisation.")
    end
  end
end
