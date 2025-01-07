class Users::InvitationsController < ApplicationController
  skip_before_action :authenticate_user!, :redirect_user_with_no_organisation, only: %i[edit update]

  before_action :authenticate_inviter!, only: %i[new create]
  before_action :delete_user_record, if: :user_should_be_cleared?, only: :create
  after_action :confirm_new_user_membership, only: :update

  def new
    @user = User.new
  end

  def create
    @user = User.find_or_initialize_by(invite_params)
    if @user.invalid? || user_belongs_to_current_organisation?
      @user.errors.add(:email, :taken) if user_belongs_to_current_organisation?
      render(params[:user][:source] == "invite_admin" ? :invite_second_admin : :new)
      return
    end

    unless @user.persisted?
      token = Devise.friendly_token[0, 20]
      @user.invitation_token = token
      @user.invitation_sent_at = Time.zone.now.utc
      @user.skip_confirmation_notification!
      @user.save!
      add_user_to_organisation(@user, organisation)
      GovWifiMailer.invitation_instructions(@user, token).deliver_now
      redirect_to memberships_path and return
    end

    membership = add_user_to_organisation(@user, organisation)
    send_invite_email(membership) if @user.confirmed?

    redirect_to(memberships_path, notice: "#{@user.email} has been invited to join #{organisation.name}")
  end

  def invite_second_admin
    @user = User.new
  end

  def edit
    @user = User.new(invitation_token: params[:invitation_token])
  end

  # PUT /resource/invitation
  def update
    invitation_token = params.dig(:user, :invitation_token)
    @user = User.find_by!(invitation_token:)

    parameters = params.require(:user).slice(:name, :password).merge(
      invitation_accepted_at: Time.zone.now.utc,
      invitation_token: nil,
    ).permit!

    @user.assign_attributes(parameters)
    if @user.valid?
      @user.save!
      @user.confirm
      @user.memberships.first.confirm!
      sign_in(User, @user)
      redirect_to root_path
    else
      @user.invitation_token = invitation_token
      render :edit
    end
  end

private

  def show_navigation_bars
    false if action_name == "invite_second_action"
  end

  def organisation
    current_organisation
  end

  def add_user_to_organisation(invited_user, organisation)
    membership = invited_user.memberships.find_or_create_by!(invited_by_id: current_user.id, organisation:)

    permission_level = params[:permission_level]
    membership.update!(
      can_manage_team: permission_level == "administrator",
      can_manage_locations: %w[administrator manage_locations].include?(permission_level),
    )
    membership
  end

  def send_invite_email(membership)
    GovWifiMailer.membership_instructions(
      invited_user,
      membership.invitation_token,
      organisation: membership.organisation,
    ).deliver_now
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
    redirect_to(root_path) unless current_user&.can_manage_team?(current_organisation)
  end

  def delete_user_record
    invited_user&.destroy!
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
