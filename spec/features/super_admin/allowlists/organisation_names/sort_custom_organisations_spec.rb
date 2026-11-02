describe "Sorting custom organisations in the allow list", type: :feature do
  let(:admin_user) { create(:user, :super_admin) }

  before do
    create(:custom_organisation_name, name: "  Zeta Org  ")
    create(:custom_organisation_name, name: "Alpha Org")
    sign_in_user admin_user
    visit super_admin_allowlist_organisation_names_path
  end

  it "lists custom organisations in ascending alphabetical order despite surrounding whitespace" do
    rows = page.all("tbody tr")
    names = rows.map(&:text)
    expect(names.index { |t| t.include?("Alpha") }).to be < names.index { |t| t.include?("Zeta") }
  end
end
