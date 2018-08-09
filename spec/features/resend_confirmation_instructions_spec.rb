require 'features/support/sign_up_helpers'
require 'features/support/errors_in_form'

describe 'Resending confirmation instructions' do
  let(:correct_email) { 'user@user.com' }

  context 'when user has not been confirmed' do
    before do
      sign_up_for_account(email: correct_email)
      visit new_user_confirmation_path
      fill_in 'user_email', with: entered_email
      click_on 'Resend confirmation instructions'
    end

    context 'when entering correct information' do
      let(:entered_email) { correct_email }

      it 'resends the confirmation link' do
        expect(ActionMailer::Base.deliveries.count).to eq(2)
      end
    end

    context 'when email cannot be found' do
      let(:entered_email) { 'not@correct.com' }

      it_behaves_like 'errors in form'

      it 'displays an error to the user' do
        expect(page).to have_content 'Email not found'
      end
    end
  end

  context 'when user has been confirmed' do
    before do
      sign_up_for_account(email: correct_email)
      create_password_for_account
      visit new_user_confirmation_path
      fill_in 'user_email', with: correct_email
      click_on 'Resend confirmation instructions'
    end

    it_behaves_like 'errors in form'

    it 'tells the user this email has already been confirmed' do
      expect(page).to have_content 'Email was already confirmed'
    end
  end
end
