class Users::InvitationsController < ApplicationController
  skip_before_action :authenticate_user!, :redirect_user_with_no_organisation, only: %i[edit update]

  def new
    @user = User.new
  end

  def create
    user = User.create(email: params[:invitation_form][:email])
    Membership.create(user:, organisation: current_organisation)
    redirect_to memberships_path
  end

  def edit
    @user = User.new(invitation_token: params[:invitation_token])
  end

  def update
     redirect_to root_path
  end

  def invite_second_admin
    @user = User.new
  end

private

  def invitation_params
    params.require(:invitation_form).permit(:email)
  end

  def show_navigation_bars
    false if action_name == "invite_second_action"
  end
end
