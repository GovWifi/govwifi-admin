class Users::InvitationsController < Devise::InvitationsController
  before_action :show_navigation_bars
  before_action :delete_user_record, if: :user_should_be_cleared?, only: :create
  after_action :confirm_new_user_membership, only: :update # rubocop:disable Rails/LexicallyScopedActionFilter

  def create
    if user_is_invalid? || user_belongs_to_current_organisation?
      self.resource = invite_resource
      render(params[:user][:source] == "invite_admin" ? :invite_second_admin : :new)
      return
    end

    self.resource = invite_resource unless user_belongs_to_other_organisations?

    add_user_to_organisation(organisation)

    redirect_to(memberships_path, notice: "#{invited_user.email} has been invited to join #{organisation.name}")
  end

  def invite_second_admin
    @user = User.new
  end

private

  def show_navigation_bars
    false if action_name == "invite_second_action"
  end

  def organisation
    current_organisation
  end

  def add_user_to_organisation(organisation)
    membership = invited_user.memberships.find_or_create_by!(invited_by_id: current_user.id, organisation:)
    membership.permission_level = params[:permission_level]
    membership.save!
    send_invite_email(membership) if user_has_confirmed_account?
  end

  def send_invite_email(membership)
    GovWifiMailer.membership_instructions(
      invited_user,
      membership.invitation_token,
      organisation: membership.organisation,
    ).deliver_now
  end

  def user_has_confirmed_account?
    invited_user.confirmed?
  end

  def user_belongs_to_current_organisation?
    invited_user&.confirmed? && invited_user.organisations.include?(organisation)
  end

  def user_belongs_to_other_organisations?
    invited_user.present? &&
      invited_user.confirmed? &&
      invited_user.organisations.pluck(:id).exclude?(current_organisation&.id)
  end

  def authenticate_inviter!
    # https://github.com/scambra/devise_invitable#controller-filter
    unless current_user&.can_manage_team?(current_organisation)
      redirect_to(root_path) and return
    end
  end

  def delete_user_record
    invited_user.destroy! unless invited_user.nil?
  end

  def user_is_invalid?
    !invite_params[:email].match? Devise.email_regexp
  end

  def invited_user
    User.find_by(email: invite_params[:email])
  end

  def resending_invite?
    !!params[:resend]
  end

  def user_should_be_cleared?
    resending_invite? || unconfirmed_user_with_no_org?
  end

  def unconfirmed_user_with_no_org?
    invited_user_already_exists? &&
      invited_user_not_confirmed? &&
      invited_user_has_no_org? &&
      !invited_user.is_super_admin?
  end

  def invited_user_already_exists?
    !!invited_user
  end

  def invited_user_not_confirmed?
    !invited_user.confirmed?
  end

  def invited_user_has_no_org?
    invited_user.organisations.empty?
  end

  def confirm_new_user_membership
    current_user.default_membership.confirm! if current_user
  end

  # Overrides https://github.com/scambra/devise_invitable/blob/master/app/controllers/devise/invitations_controller.rb#L105
  def invite_params
    params.require(:user).permit(:email)
  end
end
