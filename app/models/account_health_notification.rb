class AccountHealthNotification < ApplicationRecord
  ISSUES = UseCases::AccountHealth::Checks::RULES.map(&:to_s).freeze

  belongs_to :organisation
  has_many :recipients, class_name: "AccountHealthNotificationRecipient", dependent: :destroy

  validates :issue, inclusion: { in: ISSUES }
  validates :detected_at, presence: true

  scope :open, -> { where(resolved_at: nil) }

  def self.open_key_for(organisation_id, issue)
    "#{organisation_id}:#{issue}"
  end

  def resolve!(at: Time.zone.now)
    update!(resolved_at: at, open_key: nil)
  end
end
