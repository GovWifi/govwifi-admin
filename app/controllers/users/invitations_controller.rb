class Users::InvitationsController < ApplicationController
  skip_before_action :authenticate_user!, :redirect_user_with_no_organisation, only: %i[edit update]

  rescue_from AcceptInvitationForm::InvalidTokenError, with: :error_handler
  rescue_from InvitationForm::InvalidPermissionsError, with: :error_handler
  # new invitation
  def new
    @invitation_form = InvitationForm.new(inviter: current_user, organisation: current_organisation)
  end

  # send the invitation
  def create
    @invitation_form = InvitationForm.new(invitation_params)
    if @invitation_form.valid?
      @invitation_form.save!

      redirect_to memberships_path, notice: "#{@invitation_form.email} has been invited to join #{current_organisation.name}"
    else
      render(params.dig(:invitation_form, :source) == "invite_admin" ? :invite_second_admin : :new)
    end
  end

  # invitee accepts the invitation - ask name / password if required
  def edit
    @form = AcceptInvitationForm.new(invitation_token: params[:invitation_token])
  end

  # invitee accepts the invitation
  def update
    invitation_params = params.require(:accept_invitation_form).permit(:password, :name, :invitation_token)
    @form = AcceptInvitationForm.new(invitation_params)
    if @form.save!
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
    redirect_to memberships_path, notice: "Invitation email has been resent to #{email}."
  end

  def invite_second_admin
    @form = InvitationForm.new(inviter: current_user, organisation: current_organisation)
  end

private

  def error_handler(exception)
    redirect_to new_user_session_path, alert: exception.message
  end

  def invitation_token
    params[:invitation_token] || params.dig(:accept_invitation_form, :invitation_token)
  end

  def invitation_params
    parameters = params.require(:invitation_form).permit(:email, :permission_level)
    parameters.merge(inviter: current_user, organisation: current_organisation)
  end

  def show_navigation_bars
    action_name != "invite_second_action"
  end
end
