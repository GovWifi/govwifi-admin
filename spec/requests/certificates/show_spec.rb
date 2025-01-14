describe "GET /certificate/:id", type: :request do
  let(:certificate) { create(:certificate, organisation:) }
  let(:organisation) { create(:organisation, :with_cba_enabled) }
  let(:user) { create(:user, :confirm_all_memberships, organisations: [organisation]) }
  subject(:perform) { get certificate_path(certificate) }
  before :each do
    https!
    sign_in_user(user)
  end

  include_examples "user is not a member of the certificate's organisation"
  include_examples "cba flag and location permissions"

  it "successfully renders the show certificate template" do
    perform
    expect(response).to have_http_status(:success)
    expect(response).to render_template(:show)
  end
end
