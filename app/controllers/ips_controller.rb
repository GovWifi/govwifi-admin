class IpsController < ApplicationController
  def index
    set_ip_or_location_to_delete
    set_radius_key_rotation
    locations_scope = Location.includes(:ips)
      .where(organisation: current_organisation)
    if params[:search].present?
      locations_scope = locations_scope.where(
        "postcode like ?", "%#{params[:search]}%"
      ).or(
        locations_scope.where(
          "locations.address like ?", "%#{params[:search]}%"
        ),
      ).or(
        locations_scope.where(
          "ips.address like ?", "%#{params[:search]}%"
        ),
      ).references(:ips)
    end
    @pagy, @locations = pagy(locations_scope.order(:address))
  end

  def destroy
    ip = current_organisation.ips.find_by(id: params.fetch(:id))
    redirect_to ips_path && return unless ip

    ip.destroy!
    UseCases::PerformancePlatform::PublishLocationsIps.new.execute
    UseCases::Radius::PublishRadiusIpAllowlist.new.execute
    redirect_to ips_path, notice: "Successfully removed IP address #{ip.address}"
  end

private

  def set_radius_key_rotation
    if key_rotation_requested?
      @key_to_rotate = current_organisation
      .locations
      .find_by(id: params.fetch(:location_id))
    end
  end

  def set_ip_or_location_to_delete
    if ip_removal_requested?
      @ip_to_delete = current_organisation.ips.find_by(id: params.fetch(:ip_id))
    elsif location_removal_requested?
      @location_to_delete = current_organisation
        .locations
        .find_by(id: params.fetch(:location_id))
    end
  end

  def ip_removal_requested?
    params[:ip_id].present? && params[:confirm_remove].present?
  end

  def key_rotation_requested?
    params[:location_id].present? && params[:confirm_rotate].present?
  end

  def location_removal_requested?
    params[:location_id].present? && params[:confirm_remove].present?
  end
end
