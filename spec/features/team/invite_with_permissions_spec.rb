describe "Set user permissions on invite", type: :feature do
  let(:organisation) { create(:organisation) }
  let(:user) { create(:user, :confirm_all_memberships, organisations: [organisation]) }
  let(:invited_email) { "invited@gov.uk" }
  let(:invited_user) { User.find_by(email: invited_email) }

  before do
    sign_in_user user
    visit new_user_invitation_path
    fill_in "Email", with: invited_email
  end

  context "for administrators" do
    before do
      choose "Administrator"
      click_on "Send invitation email"
    end

    it "assigns the correct permissions" do
      expect(invited_user.membership_for(organisation).can_manage_team?).to eq(true)
      expect(invited_user.membership_for(organisation).can_manage_locations?).to eq(true)
    end
  end

  context "for the manage locations permissions level" do
    before do
      choose "Manage locations"
      click_on "Send invitation email"
    end

    it "assigns the correct permissions" do
      expect(invited_user.membership_for(organisation).can_manage_team?).to eq(false)
      expect(invited_user.membership_for(organisation).can_manage_locations?).to eq(true)
    end
  end

  context "for the view only permissions level" do
    before do
      choose "View only"
      click_on "Send invitation email"
    end

    it "assigns the correct permissions" do
      expect(invited_user.membership_for(organisation).can_manage_team?).to eq(false)
      expect(invited_user.membership_for(organisation).can_manage_locations?).to eq(false)
    end
  end
end
