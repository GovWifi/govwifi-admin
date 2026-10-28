class Users::MembershipsController < ApplicationController
  def create
    invitation = current_user.memberships.find_by(invitation_token: params.fetch(:token))
    invitation.confirm!

    session[:organisation_id] = invitation.organisation.id
    redirect_to root_path, notice: "You have successfully joined #{invitation.organisation.display_name}"
  end
end
