describe "Bulk upload locations and IPs", type: :feature do
  let(:user) { create(:user, :with_organisation) }
  let(:organisation) { user.organisations.first }
  let!(:mou) { create(:mou, organisation: user.organisations.first, version: Mou.latest_known_version) }

  context "when there is only one administrator for the organisation" do
    before do
      sign_in_user user
      visit ips_path
      click_on "Upload multiple locations"
    end

    it "shows error summary" do
      expect(page).to have_content("There is a problem\nYou must add another administrator before you can add IPs or multiple locations.")
    end
  end

  context "when uploading a locations CSV file" do
    let!(:another_administrator) { create(:user, organisations: [user.organisations.first]) }

    before do
      sign_in_user user
      visit ips_path
      click_on "Upload multiple locations"
    end

    it "displays the bulk upload page" do
      expect(page).to have_content("Follow these steps to upload multiple addresses and IPs:")
    end

    context "when no file is chosen to upload" do
      before do
        click_on "Upload"
      end

      it "tells the user to choose a file" do
        expect(page).to have_content("Choose a file before uploading")
      end
    end

    context "when a CSV with tabs as delimiter is uploaded" do
      before do
        attach_file("Upload completed template", Rails.root.join("spec/fixtures/csv/locations_upload_no_dupes_tabs.csv"))
        click_on "Upload"
      end

      it "displays the appropriate error" do
        expect(page).to have_content("Invalid data structure").twice
      end
    end

    context "when a CSV has contains incorrect OR missing headers" do
      before do
        attach_file("Upload completed template", Rails.root.join("spec/fixtures/csv/locations_upload_invalid_headers.csv"))
        click_on "Upload"
      end

      it "displays the appropriate error" do
        expect(page).to have_content("File must use correct header names").twice
      end
    end

    context "when a CSV has only header but no data" do
      before do
        attach_file("Upload completed template", Rails.root.join("spec/fixtures/csv/locations_upload_only_headers_no_data.csv"))
        click_on "Upload"
      end

      it "displays the appropriate error" do
        expect(page).to have_content("File has no data").twice
      end
    end

    context "when a CSV has only one row of data" do
      before do
        attach_file("Upload completed template", Rails.root.join("spec/fixtures/csv/locations_upload_only_one_row_of_data.csv"))
        click_on "Upload"
      end

      it "allows one row of data to pass validation" do
        summary = "You have submitted 1 addresses and 2 IPs. You can review your uploaded locations before saving."

        expect(page).to have_content(summary)
      end
    end

    context "when a CSV has no header AND no data" do
      before do
        attach_file("Upload completed template", Rails.root.join("spec/fixtures/csv/locations_upload_blank.csv"))
        click_on "Upload"
      end

      it "displays the appropriate error" do
        expect(page).to have_content("File has no data").twice
      end
    end

    context "when a CSV with locations but no IPs is uploaded the summary page" do
      before do
        attach_file("Upload completed template", Rails.root.join("spec/fixtures/csv/locations_upload_no_ips.csv"))
        click_on "Upload"
      end

      it "displays the uploaded locations" do
        expect(page).to have_content("122 London road London Greater London")
        expect(page).to have_content("LE2 0EN")
        expect(page).to have_content("101 Avenue street Leicester Leicestershire")
        expect(page).to have_content("SE2 9TT")
      end

      it "has a save button" do
        expect(page).to have_button("Save")
      end
    end

    context "when a CSV with locations and IPs is uploaded the summary page" do
      before do
        organisation.locations << build(:location, address: "Existing Address", organisation:)
        attach_file("Upload completed template", Rails.root.join("spec/fixtures/csv/locations_upload_no_dupes.csv"))
        click_on "Upload"
      end

      it "displays total number of Locations and IP addresses uploaded in csv" do
        summary = "You have submitted 2 addresses and 3 IPs. You can review your uploaded locations before saving."

        expect(page).to have_content(summary)
      end

      it "does not display already existing locations" do
        expect(page).to_not have_content("Location address already exists for this organisation")
      end

      it "displays the uploaded locations" do
        expect(page).to have_content("122 London road London Greater London")
        expect(page).to have_content("LE2 0EN")
        expect(page).to have_content("101 Avenue street Leicester Leicestershire")
        expect(page).to have_content("SE2 9TT")
      end

      it "displays the uploaded IP addresses" do
        expect(page).to have_content("192.1.2.3")
        expect(page).to have_content("192.1.2.4")
        expect(page).to have_content("192.1.2.5")
      end

      it "has a save button" do
        expect(page).to have_button("Save")
      end
    end

    context "when a CSV has extra spaces in the data" do
      before do
        attach_file("Upload completed template", Rails.root.join("spec/fixtures/csv/locations_upload_extra_spaces.csv"))
        click_on "Upload"
      end

      it "displays data without the extra spaces" do
        expect(page).to have_content("122 London road London Greater London")
        expect(page).to have_content("LE2 0EN")
        expect(page).to have_content("101 Avenue street Leicester Leicestershire")
        expect(page).to have_content("SE2 9TT")
      end
    end

    context "when a CSV with an invalid postcode is uploaded the summary page" do
      before do
        attach_file("Upload completed template", Rails.root.join("spec/fixtures/csv/locations_upload_no_dupes_invalid_postcode.csv"))
        click_on "Upload"
      end

      it "displays the invalid postcode error message" do
        expect(page).to have_content("Postcode must be valid").twice
      end

      it "does not have a save button" do
        expect(page).not_to have_button("Save")
      end
    end

    context "when a CSV with existing locations is uploaded the summary page" do
      before do
        l = create(:location, address: "122 London road London Greater London", postcode: "LE2 0EN", organisation:)
        create(:location, address: "101 Avenue street Leicester Leicestershire", postcode: "SE2 9TT", organisation:)
        create(:ip, address: "192.1.2.3", location: l)
        create(:ip, address: "192.1.2.4", location: l)
        attach_file("Upload completed template", Rails.root.join("spec/fixtures/csv/locations_upload_no_dupes.csv"))
        click_on "Upload"
      end

      it "displays the location address error messages" do
        expect(page).to have_content("Location address already exists for this organisation", count: 4)
      end

      it "displays the IP address error messages" do
        expect(page).to have_content("IP address is already in use", count: 4)
      end

      it "does not have a save button" do
        expect(page).not_to have_button("Save")
      end
    end

    context "when a CSV with duplicate locations is uploaded the summary page" do
      before do
        attach_file("Upload completed template", Rails.root.join("spec/fixtures/csv/locations_upload_with_dupes.csv"))
        click_on "Upload"
      end

      it "displays the location address error messages" do
        expect(page).to have_content("Address 122 London road London Greater London", count: 4)
      end

      it "displays the IP address error messages" do
        expect(page).to have_content("Ip address 192.1.2.3 is a duplicate", count: 4)
        expect(page).to have_content("Ip address 192.1.2.4 is a duplicate", count: 4)
      end

      it "does not have a save button" do
        expect(page).not_to have_button("Save")
      end
    end

    context "when confirming an upload" do
      before do
        attach_file("Upload completed template", Rails.root.join("spec/fixtures/csv/locations_upload_no_dupes.csv"))
        click_on "Upload"
        click_on "Save"
      end

      it "returns to the locations page and displays an alert" do
        expect(page).to have_content("Upload complete. You have saved 2 new locations and 3 new IP addresses")
      end

      it "displays the new locations" do
        expect(page).to have_content("122 London road London Greater London")
        expect(page).to have_content("101 Avenue street Leicester Leicestershire")
      end

      it "displays the new IP addresses" do
        expect(page).to have_content("192.1.2.3")
        expect(page).to have_content("192.1.2.4")
        expect(page).to have_content("192.1.2.5")
      end
    end

    context "when not confirming an upload" do
      before do
        attach_file("Upload completed template", Rails.root.join("spec/fixtures/csv/locations_upload_no_dupes.csv"))
        click_on "Upload"
        click_on "Locations"
      end

      it "does not display the new locations" do
        expect(page).not_to have_content("122 London road London Greater London")
        expect(page).not_to have_content("101 Avenue street Leicester Leicestershire")
      end

      it "does not display the new IP addresses" do
        expect(page).not_to have_content("192.1.2.3")
        expect(page).not_to have_content("192.1.2.4")
        expect(page).not_to have_content("192.1.2.5")
      end
    end
  end
end
