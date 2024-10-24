class UserInvitationForm
  include ActiveModel::Model
  include ActiveModel::Validations

  validates :email, presence: true, format: { with: Devise.email_regexp, message: "Invalid Email address" }
  validates :permission_level, presence: true
  validate :user_is_already_a_member

  attr_accessor :email, :permission_level, :organisation

  def save!(current_inviter:)
    invited_user = User.find_or_initialize_by(email:)
    invited_user.skip_confirmation_notification!
    membership = invited_user.memberships.build(invited_by_id: current_inviter.id, organisation:)
    membership.permission_level = permission_level
    invited_user.save!(validate: false)
    token = membership.invitation_token
    UserInvitationForm.send_invite(invited_user, token, organisation)
  end

  def self.send_invite(user, token, organisation)
    user.confirmed? ? self.send_cross_organisational_email(user, token, organisation) : self.send_invite_new_user(user, token)
  end

  def self.send_invite_new_user(user, token)
    GovWifiMailer.invitation_instructions(user, token).deliver_now
  end

  def self.send_cross_organisational_email(user, token, organisation)
    GovWifiMailer.membership_instructions(user, token, organisation:).deliver_now
  end

private

  def user
    @user ||= User.find_by(email:)
  end

  def user_is_already_a_member
    if user&.membership_for(organisation)
      errors.add(:invalid, "This email address is already associated with an administrator account")
    end
  end

  def must_be_signed
    errors.add(:email, :permission_level)
  end
end
