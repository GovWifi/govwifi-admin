describe "Change Permissions", type: :feature do
  let(:organisation) { create(:organisation) }

  context "there are two users with administrator privileges" do
    before do
      users = create_list(:user, 2, :confirm_all_memberships, organisations: [organisation])
      sign_in_user users.first
    end
    it "does not allow to decrease someone's administrator privileges" do
      visit memberships_path
      click_on "Edit permissions"
      choose "View only"
      click_on "Save"
      expect(page).to have_text("You must add another administrator before you can change")
    end
  end
end
