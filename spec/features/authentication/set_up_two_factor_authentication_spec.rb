describe "Set up two factor authentication", type: :feature do
  let(:user) { create(:user, :with_organisation) }

  before do
    sign_in_user(user, pass_through_two_factor: false)
    visit root_path
  end

  it "enforces 2FA setup" do
    expect(page).to have_current_path(users_two_factor_authentication_setup_path)
  end

  it "presents the setup page" do
    expect(page).to have_content("Set up two factor authentication")
  end

  it "explains the setup step" do
    expect(page).to have_content("Scan the QR code")
  end

  it "presents a QR code" do
    expect(page).to have_css("img[src*='data:image/png;base64']")
  end

  it "labels the text key" do
    expect(page).to have_content("Or, enter this key into your authenticator app:")
  end

  it "presents a text key" do
    expect(page).to have_content(/(([A-Z0-9]){4}  ){7}[A-Z0-9]{4}/)
  end

  it "expects a TOTP code" do
    expect(page).to have_field(:code)
  end

  it "signs out" do
    click_on "Sign out"
    expect(page).to have_content("Sign in to your GovWifi admin account")
  end

  context "when navigating to another page" do
    before { visit root_path }

    it "redirects the user back to setup" do
      expect(page).to have_current_path(users_two_factor_authentication_setup_path)
    end
  end

  context "when submitting a valid code" do
    let(:totp_double) { instance_double(ROTP::TOTP) }

    before do
      allow(ROTP::TOTP).to receive(:new).and_return(totp_double)
      allow(totp_double).to receive(:verify).and_return(true)

      fill_in :code, with: "999999"
      click_on "Complete setup"
    end

    it "authenticates the user" do
      expect(user.reload.totp_enabled?).to be true
    end

    it "shows a success message" do
      expect(page).to have_content("Two factor authentication setup successful")
    end

    it "redirects the user to invite another administrator" do
      expect(page).to have_current_path(invite_second_admin_path)
    end

    describe "A user with 2FA completed tries to access the setup page directly" do
      before :each do
        sign_out
        sign_in_user(user, pass_through_two_factor: false)
        visit(users_two_factor_authentication_setup_path)
      end
      it "redirects to the 2fa authentication path" do
        expect(page).to have_current_path(user_two_factor_authentication_path)
      end
    end

    context "with a super admin user without an organisation" do
      let(:user) { create(:user, :super_admin) }

      it "redirects the user to the super admin organisations page" do
        expect(page).to have_current_path(super_admin_organisations_path)
      end
    end

    context "with a super admin user with an organisation" do
      let(:user) { create(:user, :with_organisation, :super_admin) }

      it "redirects the user to the organisation setttings page" do
        expect(page).to have_current_path(new_organisation_settings_path)
      end
    end
  end

  context "when submitting an invalid code" do
    before do
      fill_in :code, with: "123456"
      click_on "Complete setup"
    end

    it "returns an error" do
      expect(page).to have_text("The 6 digit code entered is not valid.Check the code sent in the email or request a new email.")
    end

    it "returns to the 2FA screen" do
      expect(page).to have_content("Scan the QR code")
    end

    it "doesn't store a totp for the user" do
      expect(user.otp_secret_key).to be nil
    end
  end
end
