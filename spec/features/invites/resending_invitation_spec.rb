describe "Resending an invitation", type: :feature do
  include EmailHelpers

  let(:organisation) { create(:organisation) }
  let(:invitor) { create(:user, :confirm_all_memberships, organisations: [organisation]) }
  let(:invitee_email) { "newuser@gov.uk" }

  context "The user has been invited but not confirmed" do
    before do
      create(:membership, :unconfirmed, organisation:, user: create(:user, :unconfirmed, :skip_notification, email: invitee_email))
      sign_in_user invitor
      visit memberships_path
    end
    it "has a link to resend the invitation" do
      expect(page).to have_content("(invited) #{invitee_email}")
    end
    it "sends a invitation to confirm the users account" do
      click_on "Resend invite"
      click_on "Resend invite"
      it_sent_a_cross_organisational_invitation_email
    end
  end
  context "The user has been invited and confirmed" do
    before do
      create(:membership, :confirmed, organisation:, user: create(:user, :confirmed, email: invitee_email))
      sign_in_user invitor
      visit memberships_path
    end
    it "does not show a link to resend the invitation" do
      expect(page).to_not have_content("(invited)")
      expect(page).to_not have_link("Resend invite")
    end
  end
end
