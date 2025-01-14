describe "GET /certificates/edit/:id", type: :request do
  let(:organisation) { create(:organisation, :with_cba_enabled) }
  let(:user) { create(:user, :confirm_all_memberships, organisations: [organisation]) }
  let(:certificate) { create(:certificate, name: "OldName", organisation:) }
  let(:new_name) { "NewName" }
  let(:perform) { patch certificate_path(certificate), params: { certificate: { name: new_name } } }
  before :each do
    https!
    sign_in_user(user)
  end

  include_examples "cba flag and location permissions"
  include_examples "user is not a member of the certificate's organisation"

  describe "a valid change" do
    it "redirects to the index page" do
      perform
      expect(response).to redirect_to(certificates_path)
    end
    it "updates the certificate" do
      expect { perform }.to change { Certificate.find(certificate.id).name }.from("OldName").to(new_name)
    end
  end
  describe "an invalid change" do
    let(:new_name) { "" }
    it "renders the edit page with an error" do
      perform
      expect(response).to render_template(:edit)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
