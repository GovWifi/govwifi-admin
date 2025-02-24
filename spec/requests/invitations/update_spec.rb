describe "PUT /users/invitation", type: :request do
  include EmailHelpers

  before do
    https!
  end

  let(:name) { Faker::Name.name }
  let(:password) { "Abv45!#dae3fDjf" }
  let(:membership) { user.membership_for(organisation) }
  let(:invitation_token) { membership.invitation_token }
  let(:service_email) { "org@gov.uk" }
  let(:email) { "test@gov.uk" }
  let(:user) { User.find_by_email(email) }
  let(:organisation) { create(:organisation) }
  let(:params) { { accept_invitation_form: { invitation_token:, name:, password: } } }

  describe "the membership cannot be found" do
    it "raises an error if the invitation token is invalid" do
      put users_invitation_path({ accept_invitation_form: { invitation_token: "invalid", name:, password: } })
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to eq("Invalid invitation token")
    end
  end
  context "when the user exists and is unconfirmed" do
    before do
      create(:user, :unconfirmed, email:)
    end
    describe "the membership is unconfirmed and can be found" do
      before do
        create(:membership, :unconfirmed, organisation:, user:)
        put users_invitation_path(params)
      end
      it "confirms the membership" do
        expect(membership.reload).to be_confirmed
      end
      it "confirms the user" do
        expect(user.reload).to be_confirmed
      end
      it "sets the username and password on the user" do
        user.reload
        expect(user.name).to eq(name)
        expect(user.valid_password?(password)).to eq(true)
      end
      it "redirects to the sign in page" do
        expect(response).to redirect_to(new_user_session_path)
      end
      it "sets the flash notice message" do
        expect(flash[:notice]).to include organisation.name
      end
      context "invalid data" do
        let(:name) { "" }
        it "rejects invalid data" do
          expect(membership.reload).to_not be_confirmed
          expect(user.reload).to_not be_confirmed
          expect(response).to render_template(:edit)
        end
      end
    end
  end
  context "when the user exists and is confirmed" do
    before do
      create(:user, :confirmed, :with_organisation, email:)
    end
    describe "the membership is unconfirmed and can be found" do
      before do
        create(:membership, :unconfirmed, organisation:, user:)
        put users_invitation_path(params)
      end
      it "confirms the membership" do
        expect(membership.reload).to be_confirmed
      end
      it "does not set the username or password on the user" do
        user.reload
        expect(user.name).to_not eq(name)
        expect(user.valid_password?(password)).to eq(false)
      end
      it "redirects to the sign in page" do
        expect(response).to redirect_to(new_user_session_path)
      end
      it "sets the flash notice message" do
        expect(flash[:notice]).to include organisation.name
      end
    end
  end
end
