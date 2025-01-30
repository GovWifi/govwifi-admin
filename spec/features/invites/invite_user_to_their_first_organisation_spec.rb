describe "Inviting a user to their first organisation", type: :feature do
  include EmailHelpers

  let(:permission) { "Administrator" }
  let(:organisation) { create(:organisation) }
  let(:invitor) { create(:user, :confirm_all_memberships, organisations: [organisation]) }
  let(:password) { "As4gj4d#32dDfgwre41" }
  let(:name) { Faker::Name.name }

  context "when the user does not exist yet" do
    let(:invitee_email) { "newuser@gov.uk" }
    before do
      sign_in_user invitor
      invite(email: invitee_email, permission:)
    end
    it "sends a invitation to confirm the users account" do
      it_sent_one_email
      it_sent_a_cross_organisational_invitation_email
    end
    it "notifies the user with a success message" do
      expect(page).to have_content("#{invitee_email} has been invited to join #{organisation.name}")
    end
    context "the invitee email is invalid" do
      let(:invitee_email) { "invalid" }

      it "does not send an invitation email" do
        it_did_not_send_any_emails
      end
      it "shows an error message" do
        expect(page).to have_content "Invalid Email address"
      end
    end
    context "the invitee has the correct permissions" do
      before do
        visit memberships_path
        click_on "Edit permissions"
      end
      describe "Administrator" do
        let(:permission) { "Administrator" }
        it "selects the administrator permission" do
          expect(page).to have_checked_field("Administrator")
        end
      end
      describe "Manage Locations" do
        let(:permission) { "Manage Locations" }
        it "selects the administrator permission" do
          expect(page).to have_checked_field("Manage Locations")
        end
      end
    end
    context "when the invited user accepts the invitation" do
      before do
        sign_out
        visit Services.notify_gateway.last_invite_url
        fill_in "Your name", with: name
        fill_in "Password", with: password
        click_on "Create"
      end
      it "Shows the log in page" do
        expect(page).to have_content("Sign in to your GovWifi admin account")
      end
      it "shows a message that the user joins the organisation" do
        expect(page).to have_content("You have successfully joined #{organisation.name}")
      end
      describe "weak password" do
        let(:password) { "password" }
        it "reject a weak password" do
          expect(page).to have_content "Password is not strong enough. Choose a different password."
        end
      end
      describe "missing password" do
        let(:password) { "" }
        it "rejects an empty password" do
          expect(page).to have_content "Password can't be blank"
        end
      end
      describe "password too short" do
        let(:password) { "1" }
        it "rejects a password that is too short" do
          expect(page).to have_content "Password is too short (minimum is 6 characters)"
        end
      end
      describe "password too long" do
        let(:password) { "1" * 100 }
        it "rejects a password that is too long" do
          expect(page).to have_content "Password is too long (maximum is 80 characters)"
        end
      end
      describe "missing name" do
        let(:name) { "" }
        it "reject a missing name" do
          expect(page).to have_content "Name can't be blank"
        end
      end
      context "signing in with the new credentials" do
        before do
          sign_in(email: invitee_email, password:)
        end
        it "successfully authenticates the user using the username and password" do
          expect(page).to have_content("Sign out")
        end
        it "is a member of the new organisation" do
          within(".organisation-name") do |org_name|
            expect(org_name).to have_content(organisation.name)
          end
        end
      end
    end
  end
end
