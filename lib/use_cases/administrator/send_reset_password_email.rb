class SendResetPasswordEmail
  REFERENCE = 'reset_password_email'.freeze

  def initialize(notifications_gateway:)
    @notifications_gateway = notifications_gateway
  end

  def execute(email:, reset_url:, template_id:)
    opts = {
      email: email,
      locals: { reset_url: reset_url },
      template_id: template_id,
      reference: REFERENCE,
      email_reply_to_id: nil
    }

    notifications_gateway.send(opts)
  end

private

  attr_reader :notifications_gateway
end
