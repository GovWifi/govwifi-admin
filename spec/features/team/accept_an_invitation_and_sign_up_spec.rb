describe "Sign up from invitation", type: :feature do
  let(:invited_user_email) { "invited@gov.uk" }
  let(:organisation) { create(:organisation) }
  let(:user) { create(:user, :confirm_all_memberships, organisations: [organisation]) }

  before do
    sign_in_user user
    invite_user(invited_user_email)
    sign_out
  end

  context "when following the invite link" do
    let(:invite_link) { Services.notify_gateway.last_invite_url }
    let(:invited_user) { User.find_by(email: invited_user_email) }

    before do
      visit invite_link
    end

    it "displays the sign up page" do
      expect(page).to have_content("Create your account")
    end

    context "when setting password" do
      %w[password].each do |weak_pass|
        before do
          fill_in "Your name", with: "Ron Swanson"
          fill_in "Password", with: weak_pass
          click_on "Create my account"
        end

        it "rejects a weak password like #{weak_pass}" do
          expect(page).to have_content "Password is not strong enough. Choose a different password."
        end

        it "does not confirm the user" do
          expect(invited_user).not_to be_confirmed
        end
      end
    end

    context "when signing up as an invited user" do
      before do
        fill_in "Your name", with: "Ron Swanson"
        fill_in "Password", with: "a str0ng&secu re p4SSword"
        click_on "Create my account"
      end

      it "confirms the user" do
        expect(invited_user.confirmed?).to eq(true)
      end

      it "confirms the membership" do
        expect(invited_user.membership_for(organisation).confirmed?).to eq(true)
      end

      it "sets the users name" do
        expect(invited_user.name).to eq("Ron Swanson")
      end
    end
  end
end
