class Users::InvitationsController < ApplicationController
  skip_before_action :authenticate_user!, :redirect_user_with_no_organisation, only: %i[edit update]
  before_action :fetch_user, only: %i[edit update]
  before_action :validate_permissions, only: %i[new create]

  #new invitation
  def new
    permission_levels
    @invitation_form = InvitationForm.new
  end

  #send the invitation
  def create
    @invitation_form = InvitationForm.new(invitation_params)
    if @invitation_form.valid?
      @invitation_form.save!(current_inviter: current_user)

      redirect_to memberships_path, notice: "#{@invitation_form.email} has been invited to join #{current_organisation.name}"
    else
      permission_levels
      render(params[:invitation_form][:source] == "invite_admin" ? :invite_second_admin : :new)
    end
  end

  #invitee accepts the invitation - ask name / password if required
  def edit
    @form = AcceptInvitationForm.new(invitation_token: params[:invitation_token])
  end

  #invitee accepts the invitation
  def update
    invitation_params = params.require(:accept_invitation_form).permit(:password, :name, :invitation_token)
    @form = AcceptInvitationForm.new(invitation_params)
    if @form.save
      redirect_to new_user_session_path, notice: "You have successfully joined #{@form.organisation_name}. Please log in."
    else
      render :edit
    end
  end

  def resend
    email = params[:email]
    user = User.find_by_email(email)
    membership = user&.membership_for(current_organisation)
    raise "Cannot find membership for user #{email} and organisation #{current_organisation.name}" if user.nil? || membership.nil?
    raise "The membership for user #{email} and organisation #{current_organisation.name} has already been confirmed" if membership.confirmed?

    GovWifiMailer.membership_instructions(
      user,
      membership.invitation_token,
      organisation: membership.organisation,
      ).deliver_now
    redirect_to memberships_path
  end

  def invite_second_admin
    @form = InvitationForm.new
  end

private

  def validate_permissions
    redirect_to(root_path) unless current_user.can_manage_team?(current_organisation)
  end

  def fetch_user
    redirect_to root_path, alert: "The invitation is invalid" unless Membership.exists?(invitation_token:)
  end

  def invitation_token
    params[:invitation_token] || params.dig(:accept_invitation_form, :invitation_token)
  end

  def invitation_params
    parameters = params.require(:invitation_form).permit(:email, :permission_level)
    parameters.merge(organisation: current_organisation)
  end

  def show_navigation_bars
    false if action_name == "invite_second_action"
  end

  def permission_levels
    @permission_level_data = [
      OpenStruct.new(
        value: "administrator",
        text: "Administrator",
        hint: <<~HINT.html_safe,
          <span>View locations and IPs, team members, and logs</span><br>
          <span>Manage locations and IPs</span><br>
          <span>Add or remove team members</span><br>
          <span>View, add and remove certificates</span>
        HINT
      ),
      OpenStruct.new(
        value: "manage_locations",
        text: "Manage Locations",
        hint: <<~HINT.html_safe,
          <span>View locations and IPs, team members, and logs</span><br>
          <span>Manage locations and IPs</span><br>
          <span>Cannot add or remove team members</span><br>
          <span>View, add and remove certificates</span>
        HINT
      ),
      OpenStruct.new(
        value: "view_only",
        text: "View only",
        hint: <<~HINT.html_safe,
          <span>View locations and IPs, team members, and logs</span><br>
          <span>Cannot manage locations and IPs</span><br>
          <span>Cannot add or remove team members</span>
        HINT
      ),
    ]
  end
end
