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
