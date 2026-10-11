describe "View account health issues", type: :feature do
  include AccountHealthHelpers

  before { allow_account_health_organisation_names }

  it "lists each organisation's issues as coloured tags, linking to the organisation" do
    organisation = create(:organisation)
    sign_in_user create(:user, :super_admin)

    visit root_path
    within(".leftnav") { click_on "Account health" }

    within("#organisation-#{organisation.id}") do
      expect(page).to have_css(".govuk-tag--red", text: "No signed MoU")
      expect(page).to have_css(".govuk-tag--red", text: "Fewer than two administrators")
    end
    expect(page).to have_css("#key", text: "Notified 1 to 3 months ago")

    click_on organisation.name
    expect(page).to have_current_path(super_admin_organisation_path(organisation))
  end

  context "when signed in as an organisation user" do
    before do
      sign_in_user create(:user, :with_organisation)
      visit super_admin_account_health_path
    end

    it_behaves_like "user not authorised"
  end
end
