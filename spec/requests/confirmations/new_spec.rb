describe "GET /users/confirmations/new", type: :request do
  before do
    https!
  end
  it "renders the new template" do
    get new_user_confirmation_path
    expect(response).to render_template(:new)
  end
end
