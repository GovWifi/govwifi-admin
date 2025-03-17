class SuperAdmin::OrganisationsController < SuperAdminController
  helper_method :sort_column, :sort_direction
  before_action :set_organisation, only: %i[show destroy toggle_cba_feature]

  def index
    @organisations = Organisation.sortable_with_child_counts(sort_column, sort_direction)
    @location_count = Location.count
    respond_to do |format|
      format.html
      format.csv { send_data Organisation.all_as_csv, filename: "organisations.csv" }
    end
  end

  def service_emails
    respond_to do |format|
      format.csv { send_data Organisation.service_emails_as_csv, filename: "service_emails.csv" }
    end
  end

  def show
    @team = @organisation.users.order("#{sort_column} #{sort_direction}")
    @pagy, @locations = pagy(@organisation.locations.order("address asc"))
  end

  def destroy
    @organisation.destroy!
    redirect_to super_admin_organisations_path, notice: "Organisation has been removed"
  end

  def toggle_cba_feature
    @organisation.update!(cba_enabled: !@organisation.cba_enabled)
    redirect_to super_admin_organisation_path, notice: "Cba feature flag toggled successfully"
  end

private

  def set_organisation
    @organisation = Organisation.find(params[:id])
  end

  def sortable_columns
    %w[name created_at locations_count ips_count mous.created_at last_sign_in_at email sign_in_count certificates_count]
  end

  def sort_column
    sortable_columns.include?(params[:sort]) ? params[:sort] : "name"
  end

  def sort_direction
    directions = %w[desc asc]
    directions.include?(params[:direction]) ? params[:direction] : directions.last
  end
end
