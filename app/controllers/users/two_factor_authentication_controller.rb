class Users::TwoFactorAuthenticationController < Devise::TwoFactorAuthenticationController
  before_action :validate_can_manage_team, only: %i[edit destroy]

  def show
    user = warden.user(resource_name)
    unless user&.totp_enabled?
      redirect_to "/users/two_factor_authentication/email"
      return
    end
  end

  def edit
    @user = User.find(params.fetch(:id))
  end

  def destroy
    @user = User.find(params.fetch(:id))

    @user.reset_2fa!

    redirect_path = if current_user.super_admin?
                      super_admin_organisations_path
                    else
                      memberships_path
                    end

    redirect_to redirect_path, notice: "Two factor authentication has been reset"
  end

  def validate_can_manage_team
    user = User.find(params.fetch(:id))

    redirect_to root_path unless current_user.can_manage_other_user_for_org?(user, current_organisation)
  end
end
