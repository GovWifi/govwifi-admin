describe "Inviting a user to their first organisation", type: :feature do
  include EmailHelpers

  let(:organisation) { create(:organisation) }
  let(:invitor) { create(:user, :confirm_all_memberships, organisations: [organisation]) }
  context "when the user does not exist yet" do
    let(:invitee_email) { "newuser@gov.uk" }
    before do
      sign_in_user invitor
      visit new_users_invitation_path
      fill_in "Email", with: invitee_email
      click_on "Send invitation email"
    end

    it "sends a invitation to confirm the users account" do
      it_sent_an_invitation_email_once
    end

    it "does not send an additional membership invitation" do
      it_did_not_send_a_cross_organisational_invitation_email
    end
  end
end
