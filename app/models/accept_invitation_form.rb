class AcceptInvitationForm
  class InvalidTokenError < StandardError; end

  include ActiveModel::Model
  include ActiveModel::Validations
  include Devise::Models::Zxcvbnable

  attr_accessor :name, :password, :invitation_token

  validates :name, presence: true, if: :requires_validation

  validates :password,
            presence: true,
            length: { within: 6..80 },
            if: :requires_validation
  validate :strong_password, if: :requires_validation

  def initialize(attributes)
    super(attributes)
    raise InvalidTokenError, "Invalid invitation token" if membership.nil?
  end

  def save!
    unless user.confirmed?
      user.name = name
      user.password = password
    end

    return false if invalid?

    Membership.transaction do
      membership.confirm!
      user.confirm unless user.confirmed?
      user.save!
    end
    true
  end

  def user
    @user ||= membership&.user
  end

  def membership
    @membership ||= Membership.find_by_invitation_token(invitation_token)
  end

  def organisation_name
    @membership&.organisation&.name
  end

private

  def requires_validation
    !user.confirmed?
  end
end
