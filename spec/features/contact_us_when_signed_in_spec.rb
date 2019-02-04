xdescribe 'Contact us when signed in' do
  include_context 'with a mocked notifications client'
  include_context 'with a mocked support tickets client'

  let(:organisation) { create :organisation }
  let(:user) { create(:user, organisation: organisation) }

  before do
    sign_in_user user
    visit signed_in_new_help_path
  end

  context 'with details filled in' do
    before do
      fill_in 'Tell us about your issue', with: 'Help me barry.. im a duck too'
      click_on 'Send support request'
    end

    it 'shows a success message' do
      expect(page).to have_content('Your support request has been submitted')
    end

    it 'redirects to the home page' do
      expect(page.current_path).to eq(setup_instructions_path)
    end

    it 'opens a support ticket' do
      expect(support_tickets).to have_count 1

      # pull this stuff a level of abstraction up on the mock?
      # skip it as it's covered in the gateway specs?
      expect(support_tickets.last[:requester][:email]).to eq(
        'example@email.com'
      )

      expect(support_tickets.last.body).to eq ''
    end

    xit 'sends a help email - through notify' do
      expect(notifications.count).to eq(1)
      expect(last_notification_type).to eq 'help'
    end

    xit 'records the organisation' do
      expect(last_notification_personalisation[:organisation])
        .to eq organisation.name
    end

    xit 'records the sender' do
      expect(last_notification_personalisation[:sender_email]).to eq user.email
    end
  end

  context 'with no details filled' do
    before { click_on 'Send support request' }

    it_behaves_like 'errors in form'

    xit 'sends no emails' do
      expect(notifications).to be_empty
    end

    it 'opens no support tickets' do
      expect(support_tickets).to be_empty
    end
  end

  context 'from root/help path' do
    before { visit '/help' }

    it 'shows the user the not signed in support page' do
      expect(page).to have_content 'How can we help?'
    end
  end
end
