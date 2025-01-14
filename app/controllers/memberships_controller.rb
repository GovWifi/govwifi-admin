class MembershipsController < ApplicationController
  before_action :set_membership, only: %i[edit update destroy]
  before_action :validate_can_manage_team, only: %i[edit update destroy]
  before_action :validate_preserve_admin_permissions, only: %i[update destroy], unless: :super_admin?
  skip_before_action :redirect_user_with_no_organisation, only: %i[destroy edit update]

  def edit
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

  def update
    permission_level = params.permit(:permission_level).fetch(:permission_level)

    @membership.update!(
      can_manage_team: permission_level == "administrator",
      can_manage_locations: %w[administrator manage_locations].include?(permission_level),
    )
    flash[:notice] = "Permissions updated"
    redirect_to memberships_path
  end

  def index
    all_members = current_organisation.memberships.includes(:user)

    @member_groups = [
      {
        heading: "Administrators",
        users: all_members.filter_map { |membership| membership.user if membership.administrator? },
      },
      {
        heading: "Manage locations",
        users: all_members.filter_map { |membership| membership.user if membership.manage_locations? },
      },
      {
        heading: "View only",
        users: all_members.filter_map { |membership| membership.user if membership.view_only? },
      },
    ]

    @member_groups.each do |entry|
      entry[:users].sort! do |a, b|
        [a.name || "", a.email || ""] <=> [b.name || "", b.email || ""]
      end
    end
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
