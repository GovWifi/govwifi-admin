describe "GET /certificates/new", type: :request do
  let(:organisation) { create(:organisation, :with_cba_enabled) }
  let(:user) { create(:user, :confirm_all_memberships, organisations: [organisation]) }
  subject(:perform) { get new_certificate_path }
  before :each do
    https!
    sign_in_user(user)
  end

  include_examples "cba flag and location permissions"

  it "successfully renders the new certificate template" do
    perform
    expect(response).to have_http_status(:success)
    expect(response).to render_template(:new)
  end
end
