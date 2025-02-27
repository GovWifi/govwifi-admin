describe "GET /users/invitation/edit", type: :request do
  let(:user) { create(:user, :with_organisation) }
  let(:membership) { user.memberships.first }

  before do
    https!
  end
  it "renders the edit invitation page" do
    get edit_users_invitation_path, params: { invitation_token: membership.invitation_token }
    expect(response).to render_template(:edit)
  end
  it "raises an error if the invitation token is invalid" do
    get edit_users_invitation_path, params: { invitation_token: "invalid" }
    expect(response).to redirect_to(new_user_session_path)
    expect(flash[:alert]).to eq("Invalid invitation token")
  end
end
