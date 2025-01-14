describe "Inviting an existing user which belongs to an organisation", type: :feature do
  let!(:organisation) { create(:organisation) }
  let!(:user) { create(:user, :confirm_all_memberships, organisations: [organisation]) }

  let!(:organisation_2) { create(:organisation) }
  let!(:user_2) { create(:user, :confirm_all_memberships, email: "inviteme@gov.uk", organisations: [organisation_2]) }

  context "with a user that already belongs to an organisation" do
    before do
      sign_in_user user
      visit memberships_path
      click_link("Invite a team member", class: "govuk-button")
      fill_in "Email", with: user_2.email
      click_on "Send invitation email"
    end

    it "will show pending users which have been invited to an organisation" do
      expect(page).to have_content("#{user_2.name} (invited)")
    end
  end
end
