describe "Page header", type: :feature do
  context "when not on production" do
    before do
      Deploy.env = "test"

      visit root_path
    end

    it "contains the expected test tag" do
      expect(page).to have_content("GOV.UK GovWifi test")
    end
  end

  context "when on production" do
    before do
      Deploy.env = "production"
      visit root_path
    end

    it "does not contain the expected beta tag" do
      expect(page).to_not have_content("GOV.UK GovWifi beta")
    end
  end
end
