describe "Inviting a user to their first organisation", type: :feature do
  include EmailHelpers
  let(:invitee_email) { "newuser@gov.uk" }
  let(:password) { "asd3uhuef84£#!" }
  let(:organisation) { create(:organisation) }
  let(:invitor) { create(:user, :confirm_all_memberships, :with_2fa, organisations: [organisation]) }
  context "the user has signed up before" do
    before :each do
      sign_up_for_account(email: invitee_email)

      sign_in_user invitor
      invite(email: invitee_email)
      sign_out

      visit Services.notify_gateway.last_invite_url
      fill_in "Your name", with: Faker::Name.first_name
      fill_in "Password", with: password
      click_on "Create"
    end
    it "is a member of the organisation" do
      sign_in(email: invitee_email, password:)
      user_is_a_member_of(organisation)
    end
  end
  context "the user exists and is confirmed" do
    before do
      create(:user, :confirmed, :with_organisation, :skip_notification, email: invitee_email, password:)
      sign_in_user invitor
      invite(email: invitee_email)
    end
    it "sends a invitation to confirm the users account" do
      it_sent_one_email
      it_sent_a_cross_organisational_invitation_email
    end
    context "when the invited user accepts the invitation" do
      before do
        sign_out
        visit Services.notify_gateway.last_invite_url
        click_on "Update"
      end
      it "Shows the log in page" do
        expect(page).to have_content("Sign in to your GovWifi admin account")
      end
      it "shows a message that the user joins the organisation" do
        expect(page).to have_content("You have successfully joined #{organisation.name}")
      end
      context "signing in with the new credentials" do
        before do
          sign_in(email: invitee_email, password:)
        end
        it "successfully authenticates the user using the username and password" do
          expect(page).to have_content("Sign out")
        end
        it "is a member of the new organisation" do
          visit(change_organisation_path)
          within(".govuk-list") do |list|
            expect(list).to have_content(organisation.name)
          end
        end
      end
    end
  end
end
