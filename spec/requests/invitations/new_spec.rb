describe "GET /users/invitation/new", type: :request do
  let(:user) { create(:user, :with_organisation) }
  let(:membership) { user.memberships.first }

  before do
    https!
  end
  it "requires the user to be signed in" do
    get new_users_invitation_path
    expect(response).to redirect_to(new_user_session_path)
  end
  context "the user has signed in" do
    before do
      sign_in_user(user)
    end
    it "renders the invitation page" do
      get new_users_invitation_path
      expect(response).to render_template(:new)
    end
    it "should have the required permissions" do
      membership.permission_level = Membership::Permissions::VIEW_ONLY
      membership.save!
      get new_users_invitation_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
