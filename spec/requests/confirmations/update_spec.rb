describe "PUT /users/confirmation", type: :request do
  include EmailHelpers

  before do
    https!
    Gateways::S3.new(**Gateways::S3::DOMAIN_REGEXP).write(
      "#{UseCases::Administrator::PublishEmailDomainsRegex::SIGNUP_ALLOWLIST_PREFIX_MATCHER}(gov\\.uk)$",
    )
  end

  let(:name) { "john" }
  let(:password) { "Abv45!#dae3fDjf" }
  let(:organisation_name) { Gateways::GovukOrganisationsRegisterGateway::GOVERNMENT_ORGS.last }
  let(:service_email) { "org@gov.uk" }
  let(:confirmation_token) { "abc123" }
  let(:email) { "test@gov.uk" }
  let(:user) { User.find_by_email(email) }
  let(:organisation) { Organisation.find_by(name: organisation_name) }
  let(:params) do
    { user_membership_form: { name:, password:, organisation_name:, service_email:, confirmation_token: } }
  end
  context "The user does not have any other organisation memberships" do
    before do
      create(:user, :unconfirmed, email:, confirmation_token:)
      put users_confirmations_path, params:
    end
    it "confirms the user" do
      expect(user).to be_confirmed
    end
    it "sets all parameters" do
      expect(user.name).to eq(name)
      expect(user.valid_password?(password)).to eq(true)
    end
    it "adds the organisation" do
      expect(organisation).to have_attributes(service_email:, name: organisation_name)
    end
    it "confirms the membership" do
      expect(user.membership_for(organisation)).to be_confirmed
    end
  end
  context "the user has other unconfirmed organisation memberships" do
    before do
      create(:user, :unconfirmed, email:, confirmation_token:)
      create_list(:membership, 2, :unconfirmed, user:, organisation: create(:organisation))
    end
    it "leaves the existing memberships unconfirmed" do
      existing_memberships = user.memberships.to_a
      expect {
        put users_confirmations_path, params:
      }.to_not(change do
        existing_memberships.map(&:reload).map(&:confirmed?)
      end)
    end
    it "confirms the new membership" do
      put(users_confirmations_path, params:)
      expect(user.membership_for(organisation)).to be_confirmed
    end
  end
  context "the user has been confirmed already" do
    before do
      create(:user, email:, confirmation_token:)
      put users_confirmations_path, params:
    end
    it "redirects the root page" do
      expect(response).to redirect_to new_user_session_path
      expect(flash[:alert]).to eq("Email was already confirmed")
    end
  end
end
