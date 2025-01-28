class User < ApplicationRecord
  has_many :memberships, inverse_of: :user, dependent: :destroy
  has_many :organisations, through: :memberships, inverse_of: :users
  has_many :mous

  accepts_nested_attributes_for :organisations, :memberships

  devise :invitable,
         :confirmable,
         :database_authenticatable,
         :registerable,
         :recoverable,
         :trackable,
         :timeoutable,
         :validatable,
         :lockable,
         :two_factor_authenticatable,
         :zxcvbnable

  has_one_time_password(encrypted: true)

  validates :name, presence: true, on: :update
  validates :password,
            presence: true,
            length: { within: 6..80 },
            on: :update,
            if: :password_present?,
            confirmation: true

  validate :strong_password, on: :update, if: :password_present?

  scope :order_by_name_and_email, lambda {
    build_order_query = Arel::Nodes::NamedFunction.new("COALESCE", [
      User.arel_table["name"],
      User.arel_table["email"],
    ]).asc
    order(build_order_query)
  }

  def password_present?
    !password.nil?
  end

  # Must be defined to allow Devise to create users without passwords
  def password_required?
    false
  end

  def invitation_pending?
    invitation_sent_at && !invitation_accepted?
  end

  def pending_membership_for?(organisation:)
    memberships.pending.where(organisation:).present?
  end

  def can_manage_team?(organisation)
    is_super_admin? || membership_for(organisation)&.can_manage_team?
  end

  def can_manage_locations?(organisation)
    is_super_admin? || membership_for(organisation).can_manage_locations?
  end

  def can_manage_certificates?(organisation)
    can_manage_locations?(organisation)
  end

  def membership_for(organisation)
    memberships.find_by(organisation:)
  end

  def default_membership
    memberships.first
  end

  def can_manage_other_user_for_org?(user, org)
    is_super_admin? || !!(can_manage_team?(org) && user.membership_for(org))
  end

  def need_two_factor_authentication?(request)
    return false if ENV.key?("BYPASS_2FA")

    needs_auth = request.env["warden"].session(:user)[TwoFactorAuthentication::NEED_AUTHENTICATION]
    needs_auth.nil? || needs_auth
  end

  def reset_2fa!
    update!(
      second_factor_attempts_count: 0,
      encrypted_otp_secret_key: nil,
      encrypted_otp_secret_key_iv: nil,
      encrypted_otp_secret_key_salt: nil,
      totp_timestamp: nil,
      otp_secret_key: nil,
    )
  end

  def send_new_otp_after_login?
    false
  end

  def self.search(search_term)
    where("email = ? OR name = ?", search_term, search_term).first ||
      find_by("name like ?", "%#{search_term}%") ||
      find_by("email like ?", "%#{search_term}%")
  end

  def self.admin_usage_csv
    CSV.generate do |csv|
      csv << ["email", "admin name", "current sign in date",	"last sign in date", "number of sign ins", "organisation name"]
      User.select("users.*, organisations.name as organisation_name").joins(:organisations).order(email: :asc).each do |data|
        csv << [data.email, data.name, data.current_sign_in_at, data.last_sign_in_at, data.sign_in_count, data.organisation_name]
      end
    end
  end

  def member_of?(organisation_id)
    Membership.exists?(organisation_id:, user: self)
  end

  def confirmed_member_of?(organisation_id)
    Membership.where.not(confirmed_at: nil).where(organisation_id:, user: self).exists?
  end

  def confirmed_organisations
    Organisation.joins(:memberships).joins(memberships: :user).where.not(memberships: { confirmed_at: nil }).where(user: { id: self })
  end
end
