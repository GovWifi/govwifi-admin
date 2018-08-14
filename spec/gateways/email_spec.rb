require 'support/notifications_service'

describe EmailGateway do
  before do
    ENV['NOTIFY_API_KEY'] = 'dummy_key-00000000-0000-0000-0000-000000000000-00000000-0000-0000-0000-000000000000'

    expect_any_instance_of(Notifications::Client).to \
      receive(:send_email).with(notifications_payload)
  end

  context 'confirmation emails' do
    let(:email) { 'test@example.com' }
    let(:confirmation_url) { 'http://example.com/confirm?token=123' }
    let(:template_id) { 1 }
    let(:reference) { 'confirmation_email' }
    let(:notifications_payload) do
      {
        email_address: 'test@example.com',
        template_id: 1,
        personalisation: { confirmation_url: 'http://example.com/confirm?token=123' },
        reference: 'confirmation_email'
      }
    end

    it 'calls notifications' do
      subject.send(
        email: email,
        template_id: template_id,
        locals: { confirmation_url: confirmation_url },
        reference: reference
      )
    end
  end
end
