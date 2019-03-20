class Admin::OrganisationsController < AdminController
  helper_method :sort_column, :sort_direction

  def index
    @organisations = Organisation
      .includes(:signed_mou_attachment)
      .order("#{sort_column} #{sort_direction}")

    @location_count = Location.count
  end

  def show
    @organisation = Organisation.find(params[:id])
    @locations = @organisation.locations.order("#{sort_column2} #{sort_direction2}")
  end

  def destroy
    organisation = Organisation.find(params[:id])
    organisation.destroy
    redirect_to admin_organisations_path, notice: "Organisation has been removed"
  end

private

  def sortable_columns
    %w[name created_at active_storage_attachments.created_at address]
  end

  def sort_column2
    sortable_columns.include?(params[:sort]) ? params[:sort] : sortable_columns.last
  end

  def sort_direction2
    %w[asc].include?(params[:direction]) ? params[:direction] : "asc"
  end

  def sort_column
    sortable_columns.include?(params[:sort]) ? params[:sort] : sortable_columns[1]
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end
end
