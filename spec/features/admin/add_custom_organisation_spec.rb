require 'support/confirmation_use_case'

describe 'adding a custom organisation name' do
  include_examples 'confirmation use case spy'

  let!(:admin_user) { create(:user, super_admin: true) }

  context 'when visiting the custom organisations page' do
    before do
      sign_in_user admin_user
      visit admin_custom_organisations_path
    end

    it 'will show the add custom organisations page' do
      expect(page.body).to have_content('Allow an organisation access to the admin platform')
    end

    it 'will redirect you to organisations page once a custom org is added' do
      fill_in "Enter the organisation's full name", with: 'Custom Org name'
      expect do
        click_on 'Allow organisation'
        .to change { CustomOrganisationName.count }.by(1)
      end
    end

    context 'sign out and find custom organisations' do
      before do
        sign_out
        CustomOrganisationName.create(name: 'Custom Org name')
        sign_up_for_account(email: 'default@gov.uk')
        visit confirmation_email_link
      end

      it 'displays the custom organisation name in the list` would be better for instance' do
        select 'Custom Org name', from: 'Organisation name'
        fill_in 'Service email', with: 'bob@gov.uk'
        fill_in 'Your name', with: 'bob'
        fill_in 'Password', with: 'bobpassword'
        click_on 'Create my account'
        expect(page).to have_content('Custom Org name')
      end
    end

    context 'when the organisation name is blank' do
      it 'will error with the reason' do
        fill_in 'custom_organisations[name]', with: ' '
        click_on 'Allow organisation'
        expect(page).to have_content("Name can't be blank")
      end
    end

    context 'after addding a custom organisation' do
      let!(:org1) { CustomOrganisationName.create(name: 'Custom Org 1') }
      let!(:org2) { CustomOrganisationName.create(name: 'Custom Org 2') }
      before do
        sign_in_user admin_user
        visit admin_custom_organisations_path
      end

      it 'lists all of the custom organisation names' do
        expect(page).to have_content('Custom Org 1')
        expect(page).to have_content('Custom Org 2')
      end
    end
  end
end
