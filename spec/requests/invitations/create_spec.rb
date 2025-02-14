describe "POST /users/invitation", type: :request do
  include EmailHelpers

  let(:email) { Faker::Internet.email }
  let(:invited_user) { User.find_by_email(email) }
  let(:user) { create(:user, :with_organisation) }
  let(:organisation) { user.organisations.first }
  let(:subject) { post users_invitation_path, params: { invitation_form: { email:, permission_level: "manage_locations" } } }
  before do
    https!
  end
  it "requires the user to be signed in" do
    post users_invitation_path, params: { invitation_form: { email:, permission_level: "manage_locations" } }
    expect(response).to redirect_to(new_user_session_path)
  end
  context "the user has signed in" do
    before do
      sign_in_user(user)
    end
    context "the invited user already exists" do
      before do
        create(:user, :with_organisation, email:)
        post users_invitation_path, params: { invitation_form: { email:, permission_level: "manage_locations" } }
      end
      it "adds an unconfirmed membership of the user's organisation to the invited user" do
        expect(invited_user.membership_for(organisation)).to_not be_confirmed
      end
      it "sets the permission on the new membership" do
        expect(invited_user.membership_for(organisation)).to be_manage_locations
      end
      it "sends an email" do
        it_sent_a_cross_organisational_invitation_email
      end
    end
    context "the invited user does not exist yet" do
      before do
        post users_invitation_path, params: { invitation_form: { email:, permission_level: "manage_locations" } }
      end
      it "creates an unconfirmed user" do
        expect(invited_user).to_not be_confirmed
      end
      it "adds an unconfirmed membership of the user's organisation to the invited user" do
        expect(invited_user.membership_for(organisation)).to_not be_confirmed
      end
      it "sets the permission on the new membership" do
        expect(invited_user.membership_for(organisation)).to be_manage_locations
      end
      it "sends an email" do
        it_sent_a_cross_organisational_invitation_email
      end
    end
    describe "invalid params" do
      it "rejects an invalid email address" do
        post users_invitation_path, params: { invitation_form: { email: "not_an_email_address", permission_level: "manage_locations" } }
        expect(invited_user).to be nil
        it_did_not_send_any_emails
        expect(response).to render_template(:new)
      end
      it "rejects an invalid permission_level" do
        post users_invitation_path, params: { invitation_form: { email:, permission_level: "not_valid" } }
        expect(invited_user).to be nil
        it_did_not_send_any_emails
        expect(response).to render_template(:new)
      end
    end
  end
end
