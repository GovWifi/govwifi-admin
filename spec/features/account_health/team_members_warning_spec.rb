describe "Account health warning on Team members", type: :feature do
  include AccountHealthHelpers

  let(:organisation) { create(:organisation) }
  let(:administrator) { add_member(organisation) }
  let!(:inactive) { add_member(organisation, signed_in_at: 2.years.ago).tap { |user| user.update!(name: "Jo Bloggs") } }

  before { allow_account_health_organisation_names }

  it "names the administrator who has not signed in for over a year, with a link to remove them" do
    sign_in_user administrator
    visit memberships_path

    within("#account-health-administrators") do
      expect(page).to have_content("Jo Bloggs hasn’t signed in for over a year.")
      expect(page).to have_link("remove them from your team", href: edit_membership_path(inactive.membership_for(organisation), remove_team_member: true))
    end
  end
end
