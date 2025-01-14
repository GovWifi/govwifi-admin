describe "Logging in after signing up", type: :feature do
  let(:correct_password) { "f1uffy-bu44ies!~plant" }

  before do
    allow(Rails.logger).to receive(:info)
    sign_up_for_account(email: "tom@gov.uk")
    update_user_details(password: correct_password)
    skip_two_factor_authentication

    click_on "Sign out"

    fill_in "Email", with: "tom@gov.uk"
    fill_in "Password", with: password

    click_on "Continue"
  end

  context "with correct password" do
    let(:password) { correct_password }

    it "signs me in" do
      expect(page).to have_content "Sign out"
    end
  end

  context "with incorrect password" do
    let(:password) { "coarse" }

    it_behaves_like "not signed in"

    it "displays an error to the user" do
      expect(page).to have_content "Invalid Email or password"
    end

    it "logs the error" do
      expect(Rails.logger).to have_received(:info).with("Invalid authentication: email: tom@gov.uk, ip: 127.0.0.1")
    end
  end
end
