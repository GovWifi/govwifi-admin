describe "Inviting a user to their first organisation", type: :feature do
  include EmailHelpers

  let(:organisation) { create(:organisation) }
  let(:invitor) { create(:user, :confirm_all_memberships, organisations: [organisation]) }
  context "when the user does not exist yet" do
    let(:invitee_email) { "newuser@gov.uk" }
    before do
      sign_in_user invitor
      visit new_user_invitation_path
      fill_in "Email", with: invitee_email
      click_on "Send invitation email"
    end

    it "sends a invitation to confirm the users account" do
      it_sent_an_invitation_email_once
    end

    it "does not send an additional membership invitation" do
      it_did_not_send_a_cross_organisational_invitation_email
    end

    context "when the invited user accepts the invitation" do
      before do
        visit Services.notify_gateway.last_invite_url
        fill_in "Your name", with: "Invitee"
        fill_in "Password", with: "beatles RUPAUL!qwe"
        click_on "Create my account"
      end

      it "confirms the user" do
        expect(User.find_by(email: invitee_email)).to be_confirmed
      end

      it "confirms the membership" do
        expect(User.find_by(email: invitee_email).membership_for(organisation)).to be_confirmed
      end

      it "allows the user to sign in successfully" do
        expect(page).to have_content "Sign out"
      end
    end
  end
end
