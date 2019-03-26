describe 'Editing an organisations details', type: :feature do
  let(:organisation) { create(:organisation, name: "Gov Org 2", service_email: "testme@gov.uk") }
  let(:user) { create(:user, organisation: organisation) }

  context 'when editing an organisation you belong to' do
    before do
      sign_in_user user
      visit edit_organisation_path(organisation)
      fill_in 'Service email', with: "NewServiceEmail@gov.uk"
      click_on 'Save'
    end

    it 'allows the user to change their service email' do
      expect(page).to have_content("NewServiceEmail@gov.uk")
    end

    it 'displays the success message to the user' do
      expect(page).to have_content("Service email updated")
    end
  end

  context 'when updating an organisation you do not belong to' do
    let(:other_user) { create(:user) }

    before do
      sign_in_user other_user
    end

    it 'will cause routing error' do
      expect {
        visit edit_organisation_path(user.organisation)
      }.to raise_error(ActionController::RoutingError)
    end
  end
end
