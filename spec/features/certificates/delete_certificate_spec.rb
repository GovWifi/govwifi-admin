describe "Delete Certificate", type: :feature do
  let(:root_subject) { "/CN=rootca" }
  let(:root_key) { OpenSSL::PKey::RSA.new(512) }
  let(:organisation) { create(:organisation, :with_cba_enabled) }
  let(:user) { create(:user, :confirm_all_memberships, organisations: [organisation]) }
  let(:root_name) { "root_cert" }
  let(:intermediate_name) { "intermediate_cert" }

  before do
    sign_in_user user
    create(:certificate, name: root_name, key: root_key, subject: root_subject, organisation:)
    create(:certificate, name: intermediate_name, issuing_key: root_key, issuing_subject: root_subject, organisation:)
    visit(certificates_path)
  end
  describe "removing a certificate" do
    describe "confirm removing a root certificate" do
      before :each do
        click_link root_name
        click_button "Remove"
      end
      it "shows a confirmation message" do
        expect(page).to have_content("Are you sure you want to remove certificate 'root_cert'")
      end
      it "cannot remove a certificate with a child" do
        click_button "Remove"
        expect(page).to have_content("Cannot remove a certificate with issued certificates. Please remove the issued certificates first.")
      end
    end
    describe "confirm removing an intermediate certificate" do
      before :each do
        click_link intermediate_name
        click_button "Remove"
      end
      it "removes the root certificate" do
        click_button "Remove"
        expect(page).to have_content("Successfully removed Certificate: #{intermediate_name}")
      end
      it "allows the root to be removed afterwards" do
        click_button "Remove"
        click_link root_name
        click_button "Remove"
        click_button "Remove"
        expect(page).to have_content("Successfully removed Certificate: #{root_name}")
      end
    end
  end
end
