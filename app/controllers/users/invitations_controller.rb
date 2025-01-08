class Users::InvitationsController < ApplicationController
  skip_before_action :authenticate_user!, :redirect_user_with_no_organisation, only: %i[edit update]

  def new
    @user = User.new
  end

  def create
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

  def show_navigation_bars
    false if action_name == "invite_second_action"
  end
end
