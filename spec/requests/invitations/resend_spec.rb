describe "POST /users/invitation/resend", type: :request do
  include EmailHelpers

  let(:email) { Faker::Internet.email }
  let(:invited_user) { User.find_by_email(email) }
  let(:organisation) { inviter.organisations.first }
  let(:inviter) { create(:user, :with_organisation) }

  before do
    https!
  end
  it "requires the user to be signed in" do
    post resend_users_invitation_path(email:)
    expect(response).to redirect_to(new_user_session_path)
  end
  context "the user has signed in" do
    before do
      sign_in_user(inviter)
    end
    it "sends an email" do
      create(:membership, :unconfirmed, organisation:, user: create(:user, :unconfirmed, :skip_notification, email:))
      post resend_users_invitation_path(email:)
      it_sent_one_email
      it_sent_a_cross_organisational_invitation_email
    end
    it "raises an error if the membership has been confirmed" do
      create(:membership, :confirmed, organisation:, user: create(:user, :confirmed, email:))
      expect {
        post resend_users_invitation_path(email:)
      }.to raise_error(/already been confirmed/)
      it_did_not_send_any_emails
    end
    it "raises an error if the user does not exist" do
      expect {
        post resend_users_invitation_path(email:)
      }.to raise_error(/Cannot find membership/)
      it_did_not_send_any_emails
    end
    it "raises an error if the membership does not exist" do
      create(:user, :unconfirmed, :skip_notification, email:)
      expect {
        post resend_users_invitation_path(email:)
      }.to raise_error(/Cannot find membership/)
      it_did_not_send_any_emails
    end
  end
end
