require "spec_helper"

RSpec.describe "Sign in with a remember_me parameter", type: :request do
  before do
    https!
  end

  it "renders the sign-in form when authentication fails" do
    post user_session_path, params: { user: { email: "nobody@example.com", password: "wrong", remember_me: "1" } }

    expect(response).to have_http_status(:ok)
  end
end
