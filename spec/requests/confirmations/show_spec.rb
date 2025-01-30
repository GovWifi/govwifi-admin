describe "GET /users/confirmations", type: :request do
  before do
    https!
  end
  it "redirects to root if the confirmation token is invalid" do
    get user_confirmation_path, params: { confirmation_token: "invalid" }
    expect(response).to redirect_to(new_user_session_path)
    expect(flash[:alert]).to eq("Invalid confirmation token")
  end
  it "redirects to root if the the user is already confirmed" do
    user = create(:user)
    get user_confirmation_path, params: { confirmation_token: user.confirmation_token }
    expect(response).to redirect_to(new_user_session_path)
    expect(flash[:alert]).to eq("Email was already confirmed")
  end
  it "renders the show template" do
    user = create(:user, :unconfirmed)
    get user_confirmation_path, params: { confirmation_token: user.confirmation_token }
    expect(response).to render_template(:show)
  end
  it "renders the show template after invalid data" do
    user = create(:user, :unconfirmed)
    get user_confirmation_path, params: { user_membership_form: { confirmation_token: user.confirmation_token } }
    expect(response).to render_template(:show)
  end
end
