describe "Add location", type: :feature do
  let(:user) { create(:user, :with_organisation) }

  before do
    sign_in_user user
    visit ips_path
    click_on "Add a location"
  end

  it "displays an instruction to add a location" do
    expect(page).to have_content("Add a location")
  end

  it "displays a Cancel link" do
    expect(page).to have_link("Cancel", href: "/ips")
  end

  context "when adding the first location" do
    context "with valid IP data" do
      before do
        fill_in "Address", with: "30 Square"
        fill_in "Postcode", with: "W1A 2AB"
      end

      it "adds the location" do
        expect { click_on "Add location" }.to change(Location, :count).by(1)
      end

      it "displays the success message to the user" do
        click_on "Add location"
        expect(page).to have_content("Added 30 Square, W1A 2AB")
      end

      it 'redirects to "After location created" path' do
        click_on "Add location"
        expect(page).to have_current_path("/ips")
      end
    end

    context "when the location address is left blank" do
      before do
        fill_in "Postcode", with: "W1A 2AB"
        click_on "Add location"
      end

      it_behaves_like "errors in form"
    end

    context "when the postcode is left blank" do
      before do
        fill_in "Address", with: "30 Square"
        fill_in "Postcode", with: ""
        click_on "Add location"
      end

      it_behaves_like "errors in form"
    end

    context "when the postcode is not valid" do
      before do
        fill_in "Address", with: "30 Square"
        fill_in "Postcode", with: "WHATEVER"
        click_on "Add location"
      end

      it "displays an error about the invalid postcode" do
        expect(page).to have_content("Postcode must be valid").twice
      end
    end
  end

  context "when trying to update a different location" do
    let(:other_loc) { create(:location, organisation: create(:organisation)) }

    before do
      visit location_add_ips_path(other_loc.id)
    end

    it "does not render the add_ips_path" do
      expect(page).to_not have_current_path(location_add_ips_path(other_loc.id))
    end
  end

  context "when logged out" do
    before do
      sign_out
      visit new_location_path
    end

    it_behaves_like "not signed in"
  end
  context "when the postcode is 'unknown'" do
    before do
      fill_in "Address", with: "30 Square"
      fill_in "Postcode", with: "unknown"
      click_on "Add location"
    end

    it "adds the location successfully" do
      expect(Location.last.postcode).to eq("unknown")
    end
  end
end
