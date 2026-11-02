describe "Switch organisations", type: :feature do
  let(:user) { create(:user, :super_admin) }

  before do
    sign_in_user user
  end

  it "can switch to an organisation that it is not a member of" do
    organisation = create(:organisation)

    visit "/"
    click_on "Assume Membership"
    click_button(organisation.name)

    expect(page).to have_css("strong", text: organisation.name)
  end
end
