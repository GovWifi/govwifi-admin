describe "GET /status", type: :request do
  before do
    https!
  end

  it "returns a not found error" do
    expect {
      get "/status"
    }.to raise_error(ActionController::RoutingError)
  end
end
