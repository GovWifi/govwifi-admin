describe "Confirming an invite to a second or subsequent organisation", type: :feature do
  let(:organisation) { create(:organisation) }
  let(:user) { create(:user, organisations: [organisation]) }
  let(:invited_user) { create(:user, :with_organisation) }
  let!(:membership) do
    create(:membership,
           user: invited_user,
           invited_by_id: user.id,
           organisation:)
  end

  context "with an existing user" do
    before do
      sign_in_user invited_user
      visit confirm_new_membership_path(token: membership.invitation_token)
    end

    it "Confirms the invitation" do
      expect(invited_user.membership_for(organisation)).to be_confirmed
    end

    it "prints a success message" do
      expect(page).to have_content("You have successfully joined #{organisation.name}")
    end
  end
end
