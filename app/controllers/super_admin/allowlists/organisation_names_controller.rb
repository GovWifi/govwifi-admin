class SuperAdmin::Allowlists::OrganisationNamesController < SuperAdminController
  helper_method :sort_column, :sort_direction

  before_action :set_organisations_from_register, only: %i[new create index]

  def index
    @custom_organisation_names = ordered_custom_orgs
  end

  def new
    @custom_organisation = CustomOrganisationName.new
  end

  def create
    @custom_organisation_names = ordered_custom_orgs
    @custom_organisation = CustomOrganisationName.new(custom_org_params)

    if @custom_organisation.save
      redirect_to super_admin_allowlist_organisation_names_path, notice: "Custom organisation has been successfully added"
    else
      render :new
    end
  end

  def destroy
    custom_org = CustomOrganisationName.find_by(id: params.fetch(:id))

    custom_org.destroy!
    redirect_to super_admin_allowlist_organisation_names_path, notice: "Successfully removed #{custom_org.name}"
  end

private

  def custom_org_params
    params.require(:custom_organisation_name).permit(:name)
  end

  def ordered_custom_orgs
    CustomOrganisationName.all.order("TRIM(name) #{sort_direction}")
  end

  def sortable_columns
    %w[name]
  end

  def sortable_directions
    %w[asc]
  end

  def sort_column
    sortable_columns.include?(params[:sort]) ? params[:sort] : sortable_columns.first
  end

  def sort_direction
    sortable_directions.include?(params[:direction]) ? params[:direction] : sortable_directions.first
  end

  def set_organisations_from_register
    @fetched_organisations_from_register = Organisation.fetch_organisations_from_register
  end
end
