class Users::InvitationsController < Devise::InvitationsController
  before_action :authorise_manage_team, only: %i(create new)
  before_action :delete_user_record, if: :resending_invite?, only: :create
  before_action :add_organisation_to_params, :validate_invited_user, only: :create

private

  def delete_user_record
    User.find_by(email: invite_params[:email]).destroy!
  end

  def resending_invite?
    !!params[:resend]
  end

  def after_invite_path_for(_resource)
    team_members_path
  end

  def add_organisation_to_params
    params[:user][:organisation_id] = current_user.organisation_id
  end

  def validate_invited_user
    return_user_to_invite_page if user_is_invalid?
  end

  def user_is_invalid?
    delete_user_record if invited_user_already_exists? && invited_user_not_confirmed? && invited_user_has_no_org?
    @user = User.new(invite_params)
    !@user.validate
  end

  def return_user_to_invite_page
    render :new, resource: @user
  end

  def invited_user_already_exists?
    !!User.find_by(email: invite_params[:email])
  end

  def invited_user_not_confirmed?
    User.find_by(email: invite_params[:email]).confirmed_at.nil?
  end

  def invited_user_has_no_org?
    User.find_by(email: invite_params[:email]).organisation_id.nil?
  end

  # Overrides https://github.com/scambra/devise_invitable/blob/master/app/controllers/devise/invitations_controller.rb#L105
  def invite_params
    params.require(:user).permit(:email, :organisation_id, permission_attributes: %i(
      can_manage_team
      can_manage_locations
    ))
  end

  def authorise_manage_team
    redirect_to(root_path) unless current_user.can_manage_team?
  end
end
