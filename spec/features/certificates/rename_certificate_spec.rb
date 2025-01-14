describe "Rename Certificate", type: :feature do
  let(:organisation) { create(:organisation, :with_cba_enabled) }
  let(:user) { create(:user, :confirm_all_memberships, organisations: [organisation]) }
  let(:name) { "root_cert" }
  let!(:certificate) { create(:certificate, name:, organisation:) }

  before do
    sign_in_user user
    visit(certificates_path)
  end
  describe "edit a certificate" do
    before :each do
      click_link name
      click_link "Rename root_cert"
    end
    it "renders the edit certificate page" do
      expect(page).to have_current_path(edit_certificate_path(certificate))
    end
    it "renames the certificate" do
      fill_in "Name", with: "MyRenamedCertificate"
      click_button("Update")
      expect(page).to have_current_path(certificates_path)
      expect(page).to have_link("MyRenamedCertificate")
      expect(page).to have_content("Successfully renamed the certificate")
    end
  end
  describe "an invalid change" do
    it "rerender the page with an error" do
      click_link name
      click_link "Rename root_cert"
      fill_in "Name", with: ""
      click_button("Update")
      expect(page).to have_content("Certificate Name can't be blank")
    end
  end
end
