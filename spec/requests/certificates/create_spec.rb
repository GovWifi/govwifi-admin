describe "POST /certificates", type: :request do
  let(:certificate_content) { StringIO.new(build(:x509_certificate)) }
  let(:certificate_file) { Rack::Test::UploadedFile.new(certificate_content, original_filename: "certificate.pem") }
  let(:certificate) { Certificate.find_by_name("test") }

  let(:organisation) { create(:organisation, :with_cba_enabled) }
  let(:user) { create(:user, :confirm_all_memberships, organisations: [organisation]) }
  let(:perform) do
    post certificates_path, params: { certificate_form: { file: certificate_file, name: "mycert" } }
  end
  before :each do
    https!
    sign_in_user(user)
  end

  context "valid certificate" do
    it "successfully creates a certificate" do
      expect {
        perform
      }.to change(Certificate, :count).by(1)
    end
    it "redirects to the certificates index page" do
      perform
      expect(response).to redirect_to certificates_path
      expect(flash[:notice]).to match(/New Certificate Added/)
    end
    include_examples "cba flag and location permissions"
  end

  context "there is no issuing certificate" do
    let(:certificate_content) do
      StringIO.new(build(:x509_certificate,
                         subject: "/CN=intermediate",
                         issuing_key: OpenSSL::PKey::RSA.new(512),
                         issuing_subject: "/CN=root"))
    end
    it "does not create a certificate" do
      expect { perform }.to_not change(Certificate, :count)
    end
    it "re-renders the new page" do
      perform
      expect(response).to render_template(:new)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  context "invalid certificate" do
    let(:certificate_content) { StringIO.new("invalid") }

    it "does not create a certificate" do
      expect { perform }.to_not change(Certificate, :count)
    end
    it "re-renders the new page" do
      perform
      expect(response).to render_template(:new)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
