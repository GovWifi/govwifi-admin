describe "POST /user/confirmation", type: :request do
  include EmailHelpers

  before do
    https!
  end

  let(:email) { "test@gov.uk" }
  let(:params) do
    { email: }
  end
  context "The user does not exist" do
    before do
      post user_confirmation_path, params: { email: }
    end
    it "redirects to the sign in page" do
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:notice]).to eq("If you have an account with us, you will receive an email with a confirmation link shortly.")
    end
    it "does not send an email" do
      it_did_not_send_any_emails
    end
  end
  context "The user exists but is confirmed" do
    before do
      create(:user, :with_organisation, email:)
      post user_confirmation_path, params: { email: }
    end
    it "redirects to the sign in page" do
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:notice]).to eq("If you have an account with us, you will receive an email with a confirmation link shortly.")
    end
    it "does not send an email" do
      it_did_not_send_any_emails
    end
  end
  context "the user is unconfirmed with has other unconfirmed organisation memberships" do
    before do
      user = create(:user, :skip_notification, :unconfirmed, email:)
      create_list(:membership, 2, :unconfirmed, user:, organisation: create(:organisation))
      post user_confirmation_path, params: { email: }
    end
    it "redirects to the sign in page" do
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:notice]).to eq("If you have an account with us, you will receive an email with a confirmation link shortly.")
    end
    it "sends an email" do
      it_sent_a_confirmation_email
    end
  end
end
