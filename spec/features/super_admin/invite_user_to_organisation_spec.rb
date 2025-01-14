describe "Inviting a team member as a super admin", type: :feature do
  let(:organisation) { Organisation.find_by_name("Gov Org 3") }
  let(:super_admin) { create(:user, :super_admin) }
  let(:email) { "barry@gov.uk" }
  let(:notify_gateway) { Services.notify_gateway }

  before do
    organisation = create(:organisation, name: "Gov Org 3")
    sign_in_user super_admin
    visit "/"
    click_on "Assume Membership"
    click_on organisation.name
    click_on "Team members"
    click_on "Invite a team member", match: :first
    fill_in "Email address", with: email
  end

  it "will take the user to the organisation when they click 'Cancel'" do
    click_on "Cancel"
    expect(page).to have_current_path(memberships_path)
  end

  it "will display the name of the organisation you want to add a team member to" do
    expect(page).to have_content("Invite a team member to #{organisation.name}")
  end

  it "creates the user when invited" do
    expect { click_on "Send invitation email" }.to change(User, :count).by(1)
  end

  it "adds the invited user to the correct organisation" do
    click_on "Send invitation email"
    user = User.find_by(email: "barry@gov.uk")
    expect(user.organisations).to eq([organisation])
  end

  it "will redirect the user to the organisation page on success" do
    click_on "Send invitation email"
    expect(page).to have_current_path(memberships_path)
  end

  context "without an email address" do
    let(:email) { "" }

    before do
      click_on "Send invitation email"
    end

    it "does not send an invite" do
      expect(notify_gateway.count_all_emails).to eq 0
    end

    it "displays the correct error message" do
      expect(page).to have_content("Email can't be blank")
    end

    context "when retrying with a valid email address" do
      let(:email_second_attempt) { "barry@gov.uk" }

      before do
        fill_in "Email address", with: email_second_attempt
        click_on "Send invitation email"
      end

      it "sends an invite" do
        expect(notify_gateway.count_all_emails).to eq 1
      end

      it "adds the invited user to the correct organisation" do
        user = User.find_by(email: "barry@gov.uk")
        expect(user.organisations).to eq([organisation])
      end

      it "will redirect the user to the organisation page on success" do
        expect(page).to have_current_path(memberships_path)
      end
    end
  end

  describe "going through the normal invite flow" do
    let(:other_organisation) { create(:organisation) }

    before do
      super_admin.memberships.create!(organisation: other_organisation).confirm!

      visit change_organisation_path
      click_on other_organisation.name

      visit memberships_path
    end

    it "sets the correct target organisation" do
      click_link("Invite a team member", class: "govuk-button")

      expect(page).to have_current_path(new_user_invitation_path)
      expect(page).to have_content "Invite a team member to #{other_organisation.name}"
    end
  end
end
