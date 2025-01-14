describe "GET /certificates/new", type: :request do
  let(:organisation) { create(:organisation, :with_cba_enabled) }
  let(:certificate) { create(:certificate, organisation:) }
  let(:user) { create(:user, :confirm_all_memberships, organisations: [organisation]) }
  subject(:perform) { get edit_certificate_path(certificate) }
  before :each do
    https!
    sign_in_user(user)
  end

  include_examples "cba flag and location permissions"

  it "successfully renders the edit certificate template" do
    perform
    expect(response).to have_http_status(:success)
    expect(response).to render_template(:edit)
  end
end
