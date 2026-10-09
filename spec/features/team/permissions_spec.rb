describe "Invite a team member", type: :feature do
  let(:organisation) { create(:organisation) }
  let(:user) { create(:user, :confirm_all_memberships, organisations: [organisation]) }

  before { sign_in_user user }

  context "with the .manage_team permission" do
    before do
      user.membership_for(organisation).update!(can_manage_team: true)
      visit memberships_path
    end

    it "shows the invite a team member link" do
      expect(page).to have_link("Invite a team member")
    end

    it "allows visiting the invites page directly" do
      visit new_users_invitation_path
      expect(page).to have_current_path(new_users_invitation_path)
    end

    it "allows re-sending invites" do
      another_user = create(:user, invitation_sent_at: Time.zone.today)
      another_user.organisations << user.organisations.first
      visit memberships_path

      expect(page).to have_link("Resend invite")
    end

    it "shows alert to remind admins there must be minimum of two administrators for each organisation" do
      expect(page).to have_content("There must be a minimum of 2 administrators for each organisation.")
    end
  end

  context "without the .manage_team permission" do
    before do
      user.membership_for(organisation).update!(can_manage_team: false)
      sign_in_user user
    end

    it "hides the invite team member link" do
      visit memberships_path

      expect(page).not_to have_link("Invite team member")
    end

    context "when visiting the new user invitation page" do
      before do
        visit new_users_invitation_path
      end

      it_behaves_like "shows the settings page"
    end

    it "does not allow re-sending invites" do
      another_user = create(:user, invitation_sent_at: Time.zone.today)
      another_user.organisations << user.organisations.first
      visit memberships_path

      expect(page).not_to have_button("Resend invite")
    end
  end
end
