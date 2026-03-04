describe "Session timeout", type: :feature do
  let(:user) { create(:user, :with_organisation) }

  context "when a user is signed in" do
    before do
      sign_in_user user
      visit root_path
    end

    it "renders the timeout so the user will be warned before session ends" do
      meta = find("meta[name='hmrc-timeout-dialog']", visible: false)

      expect(meta["data-title"]).to eq("You're about to be signed out")
      expect(meta["data-message"]).to eq("For your security, we will sign you out in")
      expect(meta["data-timeout"]).to eq(Devise.timeout_in.to_i.to_s)
      expect(meta["data-countdown"]).to eq(2.minutes.to_i.to_s)
    end

    it "configures the keep alive URL so 'Stay signed in' will keep the session alive" do
      meta = find("meta[name='hmrc-timeout-dialog']", visible: false)

      expect(meta["data-keep-alive-url"]).to eq(timeout_keep_alive_path)
      expect(meta["data-keep-alive-button-text"]).to eq("Stay signed in")
    end

    it "configures the sign out URL so 'Sign out' will end the session" do
      meta = find("meta[name='hmrc-timeout-dialog']", visible: false)

      expect(meta["data-sign-out-url"]).to eq(timeout_sign_out_path)
      expect(meta["data-sign-out-button-text"]).to eq("Sign out")
    end
  end

  context "when a user is not signed in" do
    it "does not render the timeout" do
      visit root_path

      expect(page).not_to have_css("meta[name='hmrc-timeout-dialog']", visible: false)
    end
  end

  context "when the user uses the timeout actions" do
    before do
      sign_in_user user
      visit root_path
    end

    it "keeps the session alive when the user clicks the Stay signed in button" do
      visit timeout_keep_alive_path
      visit memberships_path

      expect(page).to have_content("Invite a team member")
    end

    it "signs the user out when the user clicks the Sign out button" do
      visit destroy_user_session_path
      visit memberships_path

      expect(page).to have_field("Email")
      expect(page).to have_field("Password")
      expect(page).to have_button("Continue")
    end
  end
end
