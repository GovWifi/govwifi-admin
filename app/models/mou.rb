class Mou < ApplicationRecord
  belongs_to :organisation
  belongs_to :user, optional: true

  validates :name, :email_address, :job_role, presence: true
  validates :email_address, format: { with: Devise.email_regexp }

  delegate :name, to: :organisation, prefix: true

  def formatted_date
    created_at.strftime("%-d %B %Y")
  end

  def self.latest_known_version
    BigDecimal(ENV.fetch("LATEST_MOU_VERSION", "1.0"))
  end
end
