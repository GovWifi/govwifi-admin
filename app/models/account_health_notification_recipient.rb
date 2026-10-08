class AccountHealthNotificationRecipient < ApplicationRecord
  MAX_ATTEMPTS = 3

  belongs_to :account_health_notification
  belongs_to :user, optional: true

  validates :email_address, presence: true

  scope :unsent, -> { where(sent_at: nil) }
  scope :retryable, -> { unsent.where(attempts: ...MAX_ATTEMPTS) }
end
