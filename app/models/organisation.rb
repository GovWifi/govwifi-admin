class Organisation < ApplicationRecord
  CSV_HEADER = ["Name", "Created At", "MOU Signed", "Locations", "IPs"].freeze
  has_many :mous, dependent: :destroy
  has_many :memberships, inverse_of: :organisation, dependent: :destroy
  has_many :users, through: :memberships, inverse_of: :organisations
  has_many :locations, dependent: :destroy
  has_many :ips, through: :locations
  has_many :certificates, dependent: :destroy
  has_one :nomination

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :service_email, format: { with: Devise.email_regexp }
  validate :validate_in_register?

  validates :cba_enabled, inclusion: { in: [true, false] }, allow_nil: true

  validates_associated :locations

  delegate :resign_mou?, to: :mou, allow_nil: true

  def latest_signed_mou_version
    return BigDecimal("0") if mous.empty?

    mous.last.version
  end

  def formatted_latest_mou_version
    latest_mou_version.nil? ? "" : sprintf("%.1f", latest_mou_version)
  end

  def formatted_date
    mou_version_change_date.strftime("%e %B %Y")
  end

  def resign_mou?
    return true if mous.empty?

    latest_signed_mou_version < Mou.latest_known_version
  end

  scope :sortable_with_child_counts, lambda { |sort_column, sort_direction|
    select("organisations.*,
       MAX(mous.created_at) AS latest_mou_created_at,
       COUNT(DISTINCT(locations.id)) AS locations_count,
       COUNT(DISTINCT(ips.id)) AS ips_count,
       COUNT(DISTINCT(certificates.id)) AS certificates_count")
      .left_joins(:locations).left_joins(:ips).left_joins(:mous).left_joins(:certificates)
      .group("organisations.id")
      .order(sort_column => sort_direction)
  }

  def enable_cba_feature!
    update(cba_enabled: true)
  end

  def disable_cba_feature!
    update(cba_enabled: false)
  end

  def meets_invited_admin_user_minimum?
    memberships.count(&:administrator?) >= 2
  end

  def meets_admin_user_minimum?
    memberships.count { |membership| membership.administrator? && membership.confirmed? } > 2
  end

  def ip_addresses
    ips.pluck(:address)
  end

  def validate_in_register?
    unless Organisation.fetch_organisations_from_register.include?(name)
      errors.add(:name, "Name isn't in the organisations allow list")
    end
  end

  def self.fetch_organisations_from_register
    Gateways::GovukOrganisationsRegisterGateway.new.all_orgs.sort_by(&:downcase)
  end

  def self.all_as_csv
    CSV.generate do |csv|
      csv << CSV_HEADER
      Organisation.includes(:mous).sortable_with_child_counts("name", "asc").each do |o|
        mou_signed_at = o.mous.present? ? o.mous.map(&:created_at).join(", ") : "-"
        csv << [o.name, o.created_at, mou_signed_at, o.locations_count, o.ips_count]
      end
    end
  end

  def self.service_emails_as_csv
    CSV.generate do |csv|
      csv << ["Service email address", "Org name", "User name", "Created at"]
      Organisation
        .select("organisations.*, users.name AS user_name")
        .joins("LEFT OUTER JOIN users ON users.email = organisations.service_email").each do |o|
        csv << [o.service_email, o.name, o.user_name, o.created_at]
      end
    end
  end
end
