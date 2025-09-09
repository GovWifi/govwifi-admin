class LocationsController < ApplicationController
  before_action :authorise_manage_locations
  before_action :authorise_manage_current_location, only: %i[add_ips update_ips update edit]
  before_action :authorise_ip_actions, only: %i[bulk_upload add_ips]

  def new
    @location = Location.new
  end

  def create
    @location = Location.new(
      address: params.dig(:location, :address),
      postcode: params.dig(:location, :postcode),
      organisation_id: current_organisation.id,
    )

    if @location.save
      redirect_to(ips_path, notice: "Added #{@location.full_address}")
    else
      render :new
    end
  end

  def edit
    @location = Location.find(params[:id])
  end

  def update
    location = Location.find(params[:id])
    location.update!(radius_secret_key: rotate_radius_secret_key)
    redirect_to(ips_path, notice: "RADIUS secret key has been successfully rotated")
  end

  def update_location
    @location = Location.find(params[:location_id])
    if @location.update(
      address: params.dig(:location, :address),
      postcode: params.dig(:location, :postcode),
      organisation_id: current_organisation.id,
    )
      redirect_to(ips_path, notice: "Location updated")
    else
      render :edit
    end
  end

  def add_ips
    @ips_form = LocationIpsForm.new(location_id: location_id_params[:location_id])
  end

  def update_ips
    @ips_form = LocationIpsForm.new(ips_params.merge(location_id_params))
    if @ips_form.update(current_user, current_organisation)
      redirect_to(
        ips_path,
        notice: "Added #{@ips_form.updated_length} #{'IP address'.pluralize(@ips_form.updated_length)} to #{@ips_form.full_address}",
      )
    else
      render :add_ips
    end
  end

  def download_locations_upload_template
    send_file "public/locations_upload_template.csv", disposition: "inline"
  end

  def bulk_upload
    @upload_form = UploadForm.new
  end

  def upload_locations_csv
    @upload_form = UploadForm.new(upload_params)
    if @upload_form.invalid?
      render :bulk_upload
    else
      @parent_organisation = current_organisation
      BulkUpload::BulkUpload.add_location_data(@upload_form.data, @parent_organisation)
      @new_locations = @parent_organisation.locations.select(&:new_record?)
      @new_ips_total = @new_locations.flat_map(&:ips).count
      @parent_organisation.validate
    end
  end

  def confirm_upload
    data = params.permit(csv: {}).fetch(:csv, {}).values.map(&:values)
    raise "The uploaded file did not contain any locations." if data.empty?

    @parent_organisation = current_organisation
    BulkUpload::BulkUpload.add_location_data(data, @parent_organisation)
    @locations = @parent_organisation.locations.select(&:new_record?)
    @ips_count = @locations.flat_map(&:ips).count
    @parent_organisation.save!
    redirect_to(ips_path, notice: "Upload complete. You have saved #{@locations.count} new locations and #{@ips_count} new IP addresses")
  rescue ActiveRecord::RecordInvalid
    redirect_to(ips_path, flash: { error: "Uploading data failed. Please try again." })
  rescue StandardError => e
    redirect_to(ips_path, flash: { error: e.message })
  end

  def download_keys
    keys_csv = CSV.generate(headers: true, col_sep: "\t") do |csv|
      current_organisation.locations.each do |location|
        csv << [location[:address], location[:postcode], location[:radius_secret_key]]
      end
    end
    send_data keys_csv, filename: "keys.csv"
  end

  def destroy
    location = current_organisation.locations.find_by(id: params.fetch(:id))
    redirect_to ips_path && return unless location && location.ips.empty?

    location.destroy!
    redirect_to ips_path, notice: "Successfully removed location #{location.address}"
  end

private

  def upload_params
    params.permit(upload_form: {})[:upload_form]
  end

  def ips_params
    params.require(:location_ips_form).permit(LocationIpsForm::IP_FIELDS)
  end

  def location_id_params
    params.permit(:location_id, :location_ips_form)
  end

  def rotate_radius_secret_key
    use_case = UseCases::Administrator::GenerateRadiusSecretKey.new
    use_case.execute
  end

  def present_ips
    location_params = params
      .require(:location)
      .permit(ips_attributes: [:address])

    location_params[:ips_attributes].reject do |_, a|
      a["address"].blank? || @location.ips.map(&:address).include?(a["address"])
    end
  end

  def authorise_manage_current_location
    unless can? :edit, Location.find(params[:location_id] || params[:id])
      redirect_to root_path, error: "You are not allowed to perform this operation"
    end
  end

  def authorise_ip_actions
    unless current_organisation.mous.any?
      flash[:alert] = "Your organisation must sign the Memorandum of Understanding (MoU) before you can add IPs or multiple locations."
      redirect_to ips_path and return
    end

    unless current_organisation.meets_invited_admin_user_minimum?
      flash[:alert] = "You must add another administrator before you can add IPs or multiple locations."
      redirect_to ips_path
    end
  end
end
