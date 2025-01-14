describe "POST /users/invitation", type: :request do
  let(:user) { create(:user, :confirm_all_memberships, :with_2fa, organisations: [organisation]) }
  let(:organisation) { create(:organisation) }
  let(:notify_gateway) { Services.notify_gateway }

  before do
    https!
    login_as(user, scope: :user)
  end

  context "with tampered organisation_id parameter" do
    let(:email) { "barry@gov.uk" }
    let(:other_organisation) { create(:organisation) }

    before do
      post user_invitation_path, params: { user: {
        email:,
        organisation_id: organisation.id,
      } }
    end

    it "invites a user" do
      expect(notify_gateway.count_all_emails).to eq 1
      expect(notify_gateway.last_email_parameters).to include(template_id: NotifyTemplates.template(:invite_email))
    end

    it "ignores provided organisation_id" do
      user = User.find_by(email:)
      expect(user.organisations).to eq([organisation])
    end
  end

  context "when the user already exists and therefore is invalid" do
    before do
      post user_invitation_path, params: {
        user: {
          email: user.email,
          organisation_id: organisation.id,
          source: "invite_admin",
        },
      }
    end

    it "renders the 'invite_second_admin' template" do
      expect(response).to render_template("invite_second_admin")
    end

    it "does not create a new user" do
      expect { user.reload }.to_not change(User, :count)
    end

    it "does not send an invitation email" do
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "returns a 200 OK status" do
      expect(response).to have_http_status(:ok)
    end
  end
end
