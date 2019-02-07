describe 'adding a custom organisation name', focus: true do
  let!(:admin_user) { create(:user, super_admin: true) }

  context 'when visiting the custom organisations page' do
    before do
      sign_in_user admin_user
      visit admin_custom_organisations_path
    end

    it 'will show the add custom organisations page' do
      expect(page.body).to have_content('Add Organistions to the Register')
    end

    it 'will redirect you to organiastions page once a custom org is added' do
      fill_in 'custom_organisations[name]', with: 'Custom Org name'
      click_on 'Confirm'
      expect(page).to have_content('Successfully added a custom organisation')
    end

    context 'signout and find custom org' do
      it 'will redirect you to organiastions page once a custom org is added' do
        fill_in 'custom_organisations[name]', with: 'Custom Org name'
        click_on 'Confirm'
        sign_out
        visit confirmation_email_link
        select 'Custom Org name', from: 'Organisation name'
        expect(page).to have_content('Custom Org name')
      end
    end
  end
end
