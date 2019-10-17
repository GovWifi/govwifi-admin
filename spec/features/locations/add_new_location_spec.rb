describe 'Add location', type: :feature do
  include_context 'with a mocked notifications client'

  let(:user) { create(:user, :with_organisation) }

  before do
    sign_in_user user
    visit ips_path
    click_on 'Add a location'
  end

  it 'displays an instruction to add a location' do
    expect(page).to have_content('Add a location')
  end

  context 'when adding the first location' do
    context 'with valid IP data' do
      before do
        fill_in 'Address', with: '30 Square'
        fill_in 'Postcode', with: 'W1A 2AB'
      end

      it 'adds the location' do
        expect { click_on 'Add location' }.to change(Location, :count).by(1)
      end

      it 'displays the success message to the user' do
        click_on 'Add location'
        within('caption') do
          expect(page).to have_content('30 Square, W1A 2AB')
        end
      end

      it 'redirects to "After location created" path' do
        click_on 'Add location'
        expect(page).to have_current_path('/ips/created/location')
      end
    end

    context 'when the location address is left blank' do
      before do
        fill_in 'Postcode', with: 'W1A 2AB'
        click_on 'Add location'
      end

      it_behaves_like "errors in form"
    end

    context 'when the postcode is left blank' do
      before do
        fill_in 'Address', with: '30 Square'
        fill_in 'Postcode', with: ''
        click_on 'Add location'
      end

      it_behaves_like 'errors in form'
    end

    context 'when the postcode is not valid' do
      before do
        fill_in 'Address', with: '30 Square'
        fill_in 'Postcode', with: 'WHATEVER'
        click_on 'Add location'
      end

      it 'displays an error about the invalid postcode' do
        expect(page).to have_content('Postcode must be valid')
      end
    end
  end

  context 'when logged out' do
    before do
      sign_out
      visit new_location_path
    end

    it_behaves_like 'not signed in'
  end
end
