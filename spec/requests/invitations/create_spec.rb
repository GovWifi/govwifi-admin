describe "POST /users/invitation", type: :request do
  include EmailHelpers

  let(:email) { Faker::Internet.email }
  let(:invited_user) { User.find_by_email(email) }
  let(:user) { create(:user, :with_organisation) }
  let(:organisation) { user.organisations.first }

  before do
    https!
    sign_in_user(user)
  end

  context "the invited user does not exist yet" do
    before do
      post users_invitation_path, params: { invitation_form: { email: }}
    end
    it "creates an unconfirmed user" do
      expect(invited_user).to_not be_confirmed
    end
    it "adds an unconfirmed membership of the user's organisation to the invited user" do
      expect(invited_user.membership_for(organisation)).to_not be_confirmed
    end
  end

end
