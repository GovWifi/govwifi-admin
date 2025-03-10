class MembershipsController < ApplicationController
  before_action :set_membership, only: %i[edit update destroy]
  before_action :validate_can_manage_team, only: %i[edit update destroy]
  before_action :validate_preserve_admin_permissions, only: %i[update destroy], unless: :super_admin?
  skip_before_action :redirect_user_with_no_organisation, only: %i[destroy edit update]

  def edit; end

  def update
    permission_level = params.permit(:permission_level).fetch(:permission_level)

    @membership.permission_level = permission_level
    @membership.save!
    flash[:notice] = "Permissions updated"
    redirect_to memberships_path
  end

  def index
    @resend_email = params["resend_email"]
    all_members = current_organisation.memberships.includes(:user)
    administrators = all_members.filter_map { |membership| membership.user if membership.administrator? }
    location_managers = all_members.filter_map { |membership| membership.user if membership.manage_locations? }
    viewers =  all_members.filter_map { |membership| membership.user if membership.view_only? }
    @member_groups = [
      {
        heading: "Administrators #{display_length(administrators.count)}".html_safe,
        rows: rows(administrators)
      },
      {
        heading: "Manage locations #{display_length(location_managers.count)}".html_safe,
        rows: rows(location_managers)
      },
      {
        heading: "View only #{display_length(viewers.count)}".html_safe,
        rows: rows(viewers)
      },
    ]
  end

  def destroy
    @membership.destroy!
    @membership.user.destroy! unless @membership.user.memberships.any?

    redirect_path = if current_user.is_super_admin? && @membership.organisation_id != current_organisation&.id
                      super_admin_organisation_path(@membership.organisation)
                    else
                      memberships_path
                    end

    redirect_to redirect_path, notice: "Team member has been removed"
  end

private

  def display_length(length)
    "<span class=\"govuk-hint govuk-!-margin-bottom-0 govuk-!-display-inline-block\">(#{length})</span>"
  end

  def rows(users)
    sorted_users = users.sort_by { |user| [user.name.to_s, user.email.to_s] }
    sorted_users.map do |user|
      {
        key: { text: text(user) },
        value: { text: user.email },
        actions: actions(user),
      }
    end
  end

  def text(user)
    if user.pending_membership_for?(organisation: current_organisation)
      invited = "<span class=\"govuk-hint govuk-!-margin-bottom-0 govuk-!-display-inline-block\">(invited) </span>"
      "#{ERB::Util.html_escape user.name} #{invited}".html_safe
    else
      user.name
    end
  end

  def actions(user)
    return [] if !current_user.can_manage_team?(current_organisation) || user.id == current_user.id

    actions = [{ href: edit_membership_path(user.membership_for(current_organisation)),
                 text:"Edit",
                 visually_hidden_text: "for #{user.email}" }]

    actions << { href: { controller: "users/two_factor_authentication", action: "edit", id: user },
                 text: "Reset 2FA",
                 visually_hidden_text: "for #{user.email}" } if user.totp_enabled?

    actions << { href: memberships_path(params: { resend_email: user.email}),
                 text: "Resend invite",
                 visually_hidden_text: "for #{user.email}" } if user.pending_membership_for?(organisation: current_organisation)
    actions
  end

  def set_membership
    scope = current_user.is_super_admin? ? Membership : current_organisation.memberships
    @membership = scope.find(params.fetch(:id))
  end

  def validate_can_manage_team
    unless current_user.can_manage_team?(current_organisation)
      raise ActionController::RoutingError, "Not Found"
    end
  end

  def validate_preserve_admin_permissions
    raise ActionController::RoutingError, "Not Found" if @membership.preserve_admin_permissions?
  end
end
