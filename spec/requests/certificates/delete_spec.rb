describe "GET /certificates/edit/:id", type: :request do
  let(:organisation) { create(:organisation, :with_cba_enabled) }
  let(:user) { create(:user, :confirm_all_memberships, organisations: [organisation]) }
  let(:root_key) { OpenSSL::PKey::RSA.new(512) }
  let(:certificate) { create(:certificate, organisation:, key: root_key) }
  let(:perform) { delete certificate_path(certificate) }
  before :each do
    https!
    sign_in_user(user)
  end

  include_examples "cba flag and location permissions"
  include_examples "user is not a member of the certificate's organisation"

  it "deletes a certificate" do
    certificate
    expect { perform }.to change(Certificate, :count).from(1).to(0)
  end
  it "redirects to the index certificates page" do
    perform
    expect(response).to redirect_to certificates_path
  end
  context "there is a issued certificate" do
    before :each do
      create(:certificate, organisation:, issuing_key: root_key, issuing_subject: certificate.subject)
    end
    it "redirects with an error" do
      perform
      expect(response).to redirect_to certificates_path
      expect(flash[:alert]).to match(/Cannot remove a certificate/)
    end
    it "does not remove a certificate" do
      expect { perform }.to_not change(Certificate, :count)
    end
  end
end
