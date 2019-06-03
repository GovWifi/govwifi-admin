class Users::InvitationsController < Devise::InvitationsController
  before_action :set_target_organisation, if: :super_admin?, only: %i(create new)
  before_action :delete_user_record, if: :user_should_be_cleared?, only: :create

  def create
    if user_is_invalid?
      self.resource = invite_resource
      render :new
      return
    end

    unless user_belongs_to_other_organisations?
      self.resource = invite_resource
    end

    organisation = Organisation.find(super_admin? ? params[:organisation_id] : current_organisation.id)

    if user_belongs_to_our_organisation?(organisation)
      self.resource = invite_resource
      render :new
      return
    end

    invite_user(organisation)

    redirect_to(after_path(organisation), notice: "#{invited_user.email} has been invited to join #{organisation.name}")
  end

private

  def invite_user(organisation)
    membership = invited_user.memberships.find_or_create_by(invited_by_id: current_user.id, organisation: organisation)
    membership.update_attributes(can_manage_team: params[:can_manage_team], can_manage_locations: params[:can_manage_locations])

    send_invitation_email(membership)
  end

  def send_invitation_email(membership)
    AuthenticationMailer.membership_instructions(invited_user, membership.invitation_token, organisation: current_organisation).deliver_now
  end

  def after_path(organisation)
    super_admin? ? admin_organisation_path(organisation) : created_invite_memberships_path
  end

  def user_belongs_to_our_organisation?(organisation)
    invited_user.confirmed? && invited_user.organisations.include?(organisation)
  end

  def user_belongs_to_other_organisations?
    invited_user.present? &&
      invited_user.confirmed? &&
      invited_user.organisations.pluck(:id).exclude?(current_organisation.id)
  end

  def authenticate_inviter!
    # https://github.com/scambra/devise_invitable#controller-filter
    unless current_user&.can_manage_team?(current_organisation)
      redirect_to(root_path)
    end
  end

  def delete_user_record
    invited_user.destroy!
  end

  def set_target_organisation
    @target_organisation = Organisation.find(params[:organisation_id])
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
    invited_user_already_exists? && invited_user_not_confirmed? && invited_user_has_no_org?
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

  # Overrides https://github.com/scambra/devise_invitable/blob/master/app/controllers/devise/invitations_controller.rb#L105
  def invite_params
    params.require(:user).permit(:email)
  end
end
