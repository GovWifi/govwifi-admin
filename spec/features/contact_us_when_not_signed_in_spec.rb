describe 'Contact us when not signed in' do
  include_context 'with a mocked notifications client'

  let(:email) { 'george@gov.uk' }
  let(:name) { 'George' }
  let(:details) { 'I have an issue' }

  before { visit new_help_path }

  it 'shows the user the not signed in support page' do
    expect(page).to have_content 'How can we help?'
  end

  context "submits a support ticket'" do
    it "when a user is 'having trouble signing up'" do
      choose "I'm having trouble signing up"
      click_on('Continue')
      fill_in 'Your email address', with: email
      fill_in 'Tell us a bit more about your issue', with: details
      click_on('Submit')
      expect(page).to have_content 'Your support request has been submitted.'
    end

    it "when a user has 'something wrong with their admin account'" do
      choose "Something's wrong with my admin account"
      click_on('Continue')
      expect(page).to have_content 'Something’s wrong with my admin account'
      fill_in 'Your email address', with: email
      fill_in 'Tell us a bit more about your issue', with: details
      click_on('Submit')
      expect(page).to have_content 'Your support request has been submitted.'
    end

    it "when a user has 'a question or wants to leave feedback'" do
      choose "Ask a question or leave feedback"
      click_on('Continue')
      fill_in 'Your message', with: details
      fill_in 'Your email address', with: email
      click_on('Submit')
      expect(page).to have_content 'Your support request has been submitted.'
    end
  end

  context "when a user leaves the details field blank " do
    it 'having trouble signing up' do
      visit signing_up_new_help_path
      click_on('Submit')
      expect(page).to have_content "Details can't be blank"
    end

    it 'something wrong with their admin account' do
      visit existing_account_new_help_path
      click_on('Submit')
      expect(page).to have_content "Details can't be blank"
    end

    it 'leaving feedback' do
      visit feedback_new_help_path
      click_on('Submit')
      expect(page).to have_content "Details can't be blank"
    end

    context "checks the email is actually sent " do
      it 'signing up email sent' do
        expect {
          visit signing_up_new_help_path
          fill_in 'Your email address', with: email
          fill_in 'Tell us a bit more about your issue', with: details
          click_on 'Submit'
        }.to change {
          notifications.count
        }.by(1)
      end

      it 'existing account email sent' do
        expect {
          visit signing_up_new_help_path
          fill_in 'Your email address', with: email
          fill_in 'Tell us a bit more about your issue', with: details
          click_on 'Submit'
        }.to change {
          notifications.count
        }.by(1)
      end

      it 'feedback email sent' do
        expect {
          visit feedback_new_help_path
          fill_in 'Your email address', with: email
          fill_in 'Your message', with: details
          click_on 'Submit'
        }.to change {
          notifications.count
        }.by(1)
      end

      it 'does not send an email if the details and or email is blank' do
        visit signing_up_new_help_path
        click_on 'Submit'
        expect(notifications.count).to eq(0)
      end

      it 'records the email' do
        visit signing_up_new_help_path
        fill_in 'Your email address', with: email
        fill_in 'Tell us a bit more about your issue', with: details
        click_on 'Submit'

        expect(last_notification_personalisation[:sender_email])
          .to eq email
      end
    end
  end

  context 'from root/help path' do
    before { visit '/help' }

    it 'shows the user the not signed in support page' do
      expect(page).to have_content 'How can we help?'
    end
  end
end
