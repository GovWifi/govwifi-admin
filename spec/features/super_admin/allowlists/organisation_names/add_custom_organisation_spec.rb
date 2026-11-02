describe "Adding a custom organisation name", type: :feature do
  let(:admin_user) { create(:user, :super_admin) }

  before do
    sign_in_user admin_user
  end

  context "when visiting the custom organisations page" do
    before do
      %w[1 2 3 4].each do |num|
        CustomOrganisationName.create(name: "Custom Org #{num}")
      end
      visit super_admin_allowlist_organisation_names_path
    end

    it "displays the list of all custom organisations in alphabetical order" do
      expect(page.body).to match(/Custom Org 1.*Custom Org 2.*Custom Org 3.*Custom Org 4/m)
    end

    it "will show the add custom organisations button" do
      expect(page).to have_content("Allow an organisation")
    end
  end

  context "when adding a new custom organisation name" do
    before do
      visit super_admin_allowlist_organisation_names_path
      visit new_super_admin_allowlist_organisation_name_path
      fill_in "Enter the organisation's full name", with: name
    end

    context "with correct data" do
      let(:name) { "Custom Org name" }

      it "add the new custom organisation name" do
        expect {
          click_on "Allow organisation"
        }.to change(CustomOrganisationName, :count).by(1)
      end
    end

    context "when the organisation name has leading or trailing whitespace" do
      let(:name) { "  Custom Org name  " }

      it "stores the name stripped of surrounding whitespace" do
        expect {
          click_on "Allow organisation"
        }.to change(CustomOrganisationName, :count).by(1)

        expect(CustomOrganisationName.last.name).to eq("Custom Org name")
      end
    end

    context "when the organisation name has repeated internal whitespace" do
      let(:name) { "Custom   Org   name" }

      it "collapses internal whitespace runs to a single space" do
        expect {
          click_on "Allow organisation"
        }.to change(CustomOrganisationName, :count).by(1)

        expect(CustomOrganisationName.last.name).to eq("Custom Org name")
      end
    end

    context "when the organisation name is blank" do
      let(:name) { "" }

      before do
        click_on "Allow organisation"
      end

      it "displays an error to the user" do
        expect(page).to have_content("Name can't be blank")
      end
    end

    context "when custom organisation name already exists" do
      let(:name) { "Custom Org name" }

      before do
        CustomOrganisationName.create!(name: "Custom Org name")
        click_on "Allow organisation"
      end

      it "tells the user the name is already in our register" do
        expect(page).to have_content("Name is already in our register")
      end
    end
  end
end
