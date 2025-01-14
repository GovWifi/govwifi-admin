describe "Inviting a user to their second or subsequent organisation", type: :feature do
  include EmailHelpers

  let(:inviter_organisation) { inviter.organisations.first }
  let(:inviter) { create(:user, :with_organisation) }
  let(:invited_user) { create(:user, :with_organisation) }

  context "with a confirmed user" do
    before do
      sign_in_user inviter
      visit new_user_invitation_path
      fill_in "Email", with: invited_user.email
      click_on "Send invitation email"
    end

    it "sends a membership invitation" do
      it_sent_a_cross_organisational_invitation_email
    end

    it "does not send a new user invite" do
      it_did_not_send_an_invitation_email
    end

    it "creates a join organisation invitation" do
      expect(invited_user.memberships.count).to eq(2)
    end

    it "notifies the user with a success message" do
      expect(page).to have_content("#{invited_user.email} has been invited to join #{inviter_organisation.name}")
    end

    context "when the invited user signs in aftwards" do
      before do
        sign_out
        sign_in_user invited_user
        visit confirm_new_membership_url(token: invited_user.membership_for(inviter_organisation).invitation_token)
      end

      it "confirms the membership" do
        expect(invited_user.membership_for(inviter_organisation)).to be_confirmed
      end

      it "changes your current organisation to this organisation" do
        expect(page).to have_content("You have successfully joined #{inviter_organisation.name}")
      end
    end
  end

  context "with an unconfirmed user" do
    let(:unconfirmed_email) { "notconfirmedyet@gov.uk" }

    before do
      sign_up_for_account(email: unconfirmed_email)
      sign_in_user inviter
      visit new_user_invitation_path
      fill_in "Email", with: unconfirmed_email
      click_on "Send invitation email"
    end

    it "sends an invitation" do
      it_sent_an_invitation_email_once
    end
  end
end
