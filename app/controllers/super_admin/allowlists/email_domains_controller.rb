class SuperAdmin::Allowlists::EmailDomainsController < SuperAdminController
  helper_method :sort_column, :sort_direction

  def index
    @authorised_email_domains = ordered_email_domains
    @domain_to_remove = AuthorisedEmailDomain.find(params[:id]) if params.key?(:id)
  end

  def new
    @authorised_email_domain = AuthorisedEmailDomain.new
  end

  def create
    @authorised_email_domain = AuthorisedEmailDomain.new(authorised_email_params)

    if @authorised_email_domain.save
      publish_email_domains_regex
      publish_email_domains_list

      redirect_to super_admin_allowlist_email_domains_path, notice: "#{@authorised_email_domain.name} authorised"
    else
      render :new
    end
  end

  def destroy
    authorised_email_domain = AuthorisedEmailDomain.find_by(id: params.fetch(:id))

    authorised_email_domain.destroy!
    publish_email_domains_regex
    publish_email_domains_list

    redirect_to super_admin_allowlist_email_domains_path, notice: "#{authorised_email_domain.name} has been deleted"
  end

private

  def publish_email_domains_regex
    UseCases::Administrator::PublishEmailDomainsRegex.new.publish
  end

  def publish_email_domains_list
    UseCases::Administrator::PublishEmailDomainsList.new.publish
  end

  def authorised_email_params
    params.require(:authorised_email_domain).permit(:name)
  end

  def ordered_email_domains
    AuthorisedEmailDomain.all.order("#{sort_column} #{sort_direction}")
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
end
