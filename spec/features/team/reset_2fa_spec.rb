describe "Reset two factor authentication", type: :feature do
  let!(:super_admin_user) { create(:user, :super_admin, :with_2fa) }
  let!(:organisation) { create(:organisation, name: "Gov Org 3") }

  context "when logged in as a super admin user" do
    before do
      sign_in_user super_admin_user
      visit "/"
      click_on "Assume Membership"
      click_on organisation.name
    end

    it "shows the option to reset 2FA for org members who have 2FA enabled" do
      create(:user, :with_2fa, organisations: [organisation])
      click_on "Team members"
      expect(page).to have_content("Reset 2FA", count: 1)
    end

    it "shows the option to reset 2FA for org members who do not 2FA enabled" do
      create(:user, organisations: [organisation])
      click_on "Team members"
      expect(page).to_not have_content("Reset 2FA")
    end

    it "shows confirmation before resetting 2FA for an org member" do
      create(:user, :with_2fa, organisations: [organisation])
      click_on "Team members"
      click_on "Reset 2FA"

      expect(page).to have_content("Are you sure you want to reset")
    end

    it "resets 2FA for an org member once super admin confirms the reset" do
      user = create(:user, :with_2fa, organisations: [organisation])
      click_on "Team members"
      click_on "Reset 2FA"

      expect { click_on "Yes, reset two factor authentication" }.to change { user.reload.totp_enabled? }.from(true).to(false)
    end

    it "redirects back to org listing once 2FA has been reset" do
      create(:user, :with_2fa, organisations: [organisation])
      click_on "Team members"
      click_on "Reset 2FA"
      click_on "Yes, reset two factor authentication"

      expect(page).to have_current_path(super_admin_organisations_path)
    end

    it "shows a notice once 2FA has been reset" do
      create(:user, :with_2fa, organisations: [organisation])
      click_on "Team members"
      click_on "Reset 2FA"
      click_on "Yes, reset two factor authentication"

      expect(page).to have_content("Two factor authentication has been reset")
    end
  end
end
