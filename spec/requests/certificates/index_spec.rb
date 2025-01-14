describe "GET /certificates", type: :request do
  let(:organisation) { create(:organisation, :with_cba_enabled) }
  let(:user) { create(:user, :confirm_all_memberships, organisations: [organisation]) }
  subject(:perform) { get certificates_path }

  before :each do
    https!
    sign_in_user(user)
  end

  include_examples "cba flag and location permissions"

  it "successfully renders the index template" do
    perform
    expect(response).to have_http_status(:success)
    expect(response).to render_template(:index)
  end
end
