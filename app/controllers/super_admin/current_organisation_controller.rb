class SuperAdmin::CurrentOrganisationController < SuperAdminController
  def edit
    @organisations = Organisation.order(Organisation.sort_order(:name, :asc)).all
  end

  def update
    session[:organisation_id] = params[:organisation_id]
    redirect_to root_path
  end
end
