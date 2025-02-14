class InvitationForm
  class InvalidPermissionsError < StandardError; end

  include ActiveModel::Model
  include ActiveModel::Validations

  validates :email, presence: true, format: { with: Devise.email_regexp, message: "Invalid Email address" }
  validates :permission_level, presence: true, inclusion: { in: Membership::Permissions::ALL, message: "Invalid permission" }
  validate :user_is_already_a_member

  attr_accessor :email, :permission_level, :inviter, :organisation

  def initialize(attributes = {})
    super(attributes)
    raise InvalidPermissionsError, "Invalid permissions" unless inviter.can_manage_team?(organisation)
  end

  def save!
    invited_user = User.find_or_initialize_by(email:)
    invited_user.skip_confirmation_notification!
    membership = invited_user.memberships.build(invited_by_id: inviter.id,
                                                permission_level:,
                                                organisation:)
    invited_user.save!
    send_invite_membership_email(invited_user, membership)
  end

private

  def send_invite_membership_email(user, membership)
    GovWifiMailer.membership_instructions(
      user,
      membership.invitation_token,
      organisation: membership.organisation,
    ).deliver_now
  end

  def user_is_already_a_member
    user = User.find_by(email:)
    return if user.nil?

    if user.membership_for(organisation)
      errors.add(:email, :invalid, message: "This email address is already associated with an administrator account")
    end
  end
end
