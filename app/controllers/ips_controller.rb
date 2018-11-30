class IpsController < ApplicationController
  before_action :authorise_manage_locations, only: %i(create new)

  def new
    @ip = Ip.new
    @locations = available_locations
  end

  # rubocop:disable Style/IfInsideElse
  def create
    @ip = Ip.new(create_params)

    if @ip.save
      publish_for_performance_platform
      publish_radius_whitelist
      redirect_to(
        ips_path,
        anchor: 'ips',
        notice: "#{@ip.address} added, it will be active starting tomorrow"
      )
    else
      if adding_ip_to_location?
        @location = Location.find_by(id: ip_params[:location_id])
        render "locations/ips/new"
      else
        @locations = available_locations
        render :new
      end
    end
  end
  # rubocop:enable Style/IfInsideElse

  def index
    set_ip_to_delete if ip_removal_requested?
    @locations = Location.includes(:ips).where(organisation: current_organisation).order(:address)
  end

  def destroy
    ip = current_organisation.ips.find_by(id: params.fetch(:id))
    redirect_to ips_path && return unless ip

    ip.destroy
    redirect_to ips_path, notice: "Successfully removed IP address #{ip.address}"
  end

private

  def available_locations
    current_organisation.locations.order('address ASC').map do |loc|
      ["#{loc.address}, #{loc.postcode}", loc.id]
    end
  end

  def publish_for_performance_platform
    UseCases::PerformancePlatform::PublishLocationsIps.new(
      destination_gateway: Gateways::S3.new(
        bucket: ENV.fetch('S3_PUBLISHED_LOCATIONS_IPS_BUCKET'),
        key: ENV.fetch('S3_PUBLISHED_LOCATIONS_IPS_OBJECT_KEY')
      ),
      source_gateway: Gateways::Ips.new
    ).execute
  end

  def publish_radius_whitelist
    PublishWhitelist.new(
      destination_gateway: Gateways::S3.new(
        bucket: ENV.fetch('S3_PUBLISHED_LOCATIONS_IPS_BUCKET'),
        key: ENV.fetch('S3_WHITELIST_OBJECT_KEY')
      ),
      generate_whitelist: UseCases::Radius::GenerateRadiusIpWhitelist.new
    ).execute
  end

  def ip_params
    params.require(:ip).permit(:address, :location_id, location_attributes: %i[address postcode])
  end

  def create_params
    return params_with_new_location if user_creates_new_location?
    params_with_existing_location
  end

  def user_creates_new_location?
    ip_params[:location_id].blank?
  end

  def adding_ip_to_location?
    !ip_params.has_key?(:location_attributes)
  end

  def params_with_new_location
    p = ip_params.except(:location_id)
    p[:location_attributes][:organisation] = current_organisation
    p
  end

  def params_with_existing_location
    ip_params.except(:location_attributes)
  end

  def set_ip_to_delete
    @ip_to_delete = current_organisation.ips.find_by(id: params.fetch(:ip_id))
  end

  def ip_removal_requested?
    params[:ip_id].present?
  end
end
