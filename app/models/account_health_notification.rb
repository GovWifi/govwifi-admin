class AccountHealthNotification < ApplicationRecord
  ISSUES = UseCases::AccountHealth::Checks::RULES.map(&:to_s).freeze
  ISSUE_NAMES = {
    "no_signed_mou" => "No signed MoU",
    "missing_location_details" => "Missing location details",
    "fewer_than_two_administrators" => "Fewer than two administrators",
    "inactive_administrator" => "Administrator not signed in for over a year",
  }.freeze

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
