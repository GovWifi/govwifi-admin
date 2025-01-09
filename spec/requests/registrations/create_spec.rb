describe "POST /users", type: :request do
  include EmailHelpers

  let(:email) { "test@gov.uk" }
  let(:user) { User.find_by_email(email) }
  let(:params) { { user: { email: } } }

  before do
    https!
    Gateways::S3.new(**Gateways::S3::DOMAIN_REGEXP).write(
      "#{UseCases::Administrator::PublishEmailDomainsRegex::SIGNUP_ALLOWLIST_PREFIX_MATCHER}(gov\\.uk)$",
      )
  end
  context "The user does not exist" do
    before :each do
      post user_registration_path, params:
    end
    it "creates a new unconfirmed user with the new email address" do
      expect(user).to_not be_confirmed
    end
    it "sets the confirmation token" do
      expect(user.confirmation_token).to_not be_nil
    end
    it "redirects to the pending page" do
      expect(response).to redirect_to(users_confirmations_pending_path)
    end
    it "does not have memberships" do
      expect(user.memberships).to be_empty
    end
    it "sends a confirmation email" do
      it_sent_a_confirmation_email
    end
  end
  context "the user already exists but is not confirmed" do
    before :each do
      create(:user, :unconfirmed, email:, confirmation_token: nil)
    end
    it "does not create a new user" do
      expect { post user_registration_path, params: }.to_not change(User, :count)
    end
    it "sets the confirmation token" do
      post(user_registration_path, params:)
      expect(user.confirmation_token).to_not be_nil
    end
    it "sends a confirmation email" do
      it_sent_a_confirmation_email
    end
  end
  context "the user already exists and has been confirmed" do
    before do
      create(:user, email: "test@gov.uk")
    end
    it "does not create a new user" do
      expect { post user_registration_path, params: { user: { email: "test@gov.uk" } } }.to_not change(User, :count)
    end
    it "renders the registration page" do
      post user_registration_path, params: { user: { email: "test@gov.uk" } }
      expect(response).to render_template(:new)
    end
  end
  describe "signing up from a non-approved email domain" do
    it "does not create a new user" do
      expect { post user_registration_path, params: { user: { email: "test@nongov.uk" } } }.to_not change(User, :count)
    end
    it "renders the registration page" do
      post user_registration_path, params: { user: { email: "test@nongov.uk" } }
      expect(response).to render_template(:new)
    end
  end
end
