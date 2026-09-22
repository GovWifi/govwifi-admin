class SupportForm
  include ActiveModel::Model

  VALID_CHOICES = %w[technical_support admin_account user_support signed_in].freeze

  attr_accessor :name, :details, :email, :organisation, :phone, :subject, :choice

  validates :details, presence: true
  validates :email, presence: true, format: { with: Devise.email_regexp, message: " is not a valid email address" }
  validates :choice, inclusion: { in: VALID_CHOICES }
end
