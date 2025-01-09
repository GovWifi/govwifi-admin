class InvitationForm
  include ActiveModel::Model
  include ActiveModel::Validations

  validates :email, presence: true, format: { with: Devise.email_regexp, message: "Invalid Email address" }
  validates :permission_level, presence: true, inclusion: { in: Membership::PERMISSIONS }
  validate :user_is_already_a_member

  attr_accessor :email, :permission_level, :organisation

  def save!(current_inviter:)
    invited_user = User.find_or_initialize_by(email:)
    invited_user.skip_confirmation_notification!
    membership = invited_user.memberships.build(invited_by_id: current_inviter.id, organisation:)
    membership.permission_level = permission_level
    invited_user.save!
    send_invite_membership_email(membership)
  end

  def set_invitation_token
    self.invitation_token = Devise.friendly_token[0, 20]
  end

  private

  def send_invite_membership_email(membership)
    GovWifiMailer.membership_instructions(
      user,
      membership.invitation_token,
      organisation: membership.organisation,
      ).deliver_now
  end

  def user
    @user ||= User.find_by(email:)
  end

  def user_is_already_a_member
    if user&.membership_for(organisation)
      errors.add(:invalid, "This email address is already associated with an administrator account")
    end
  end
end
