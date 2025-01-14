describe "Resending an invitation to a team member", type: :feature do
  include EmailHelpers

  let(:invited_user_email) { "invited@gov.uk" }
  let(:user) { create(:user, :with_organisation) }

  before do
    sign_in_user user
    invite_user(invited_user_email)
    visit memberships_path
  end

  it "shows that the invitation is pending" do
    expect(page).to have_content("invited")
  end

  it "sends an invitation" do
    click_on "Resend invite"
    it_sent_an_invitation_email_twice
  end

  context "when signing up from the resent invitation" do
    let(:invited_user) { User.find_by(email: invited_user_email) }

    before do
      visit Services.notify_gateway.last_invite_url
    end

    it "displays the sign up page" do
      expect(page).to have_content("Create your account")
    end

    context "when filling in the sign up page" do
      before do
        fill_in "Your name", with: "Ron Swanson"
        fill_in "Password", with: "strong&SEKure p44sw0rd"
        click_on "Create my account"
      end

      it "saves the users name" do
        expect(invited_user.name).to eq("Ron Swanson")
      end

      it "confirms the user" do
        expect(invited_user.confirmed?).to eq(true)
        expect(invited_user.membership_for(user.organisations.first)).to be_confirmed
      end
    end
  end
end
