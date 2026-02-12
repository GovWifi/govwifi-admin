class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  default_form_builder GOVUKDesignSystemFormBuilder::FormBuilder

  include Pagy::Backend

  before_action :update_active_sidebar_path
  before_action :authenticate_user!, except: :error
  before_action :confirm_two_factor_setup, unless: :signing_out?
  before_action :redirect_user_with_no_organisation, unless: :devise_controller?
  before_action :configure_devise_permitted_parameters, if: :devise_controller?
  helper_method :current_organisation, :super_admin?
  helper_method :sidebar
  helper_method :subnav
  helper_method :show_navigation_bars
  helper_method :show_timeout?

  def error
    render :error, code: params[:code]
  end

  def show_timeout?
    show_navigation_bars
  end

  def signing_out?
    params["controller"] == "devise/sessions" && params["action"] == "destroy"
  end

  def confirm_two_factor_setup
    return if current_user.nil? ||
      !current_user.need_two_factor_authentication?(request) ||
      current_user.totp_enabled?

    redirect_to users_two_factor_authentication_setup_path
  end

  def configure_devise_permitted_parameters
    devise_parameter_sanitizer.permit(:accept_invitation, keys: [:name])
  end

  def current_organisation
    @current_organisation ||= if session[:organisation_id] && (current_user.confirmed_member_of?(session[:organisation_id].to_i) || super_admin?)
                                Organisation.find(session[:organisation_id])
                              elsif user_signed_in?
                                current_user.confirmed_organisations.first
                              end
  rescue ActiveRecord::RecordNotFound
    @current_organisation ||= current_user.confirmed_organisations.first
  end

  def super_admin?
    current_user&.is_super_admin?
  end

  def redirect_user_with_no_organisation
    return if current_user.nil?
    return if current_user.is_super_admin? && current_organisation.present?

    if current_user.is_super_admin? && current_organisation.nil?
      redirect_to super_admin_organisations_path, notice: "You have not assumed a membership."
    elsif current_user.memberships.confirmed.empty?
      redirect_to signed_in_new_help_path, notice: "You do not belong to an organisation. Please mention this in your support request."
    end
  end

protected

  def show_navigation_bars
    user_signed_in? && !current_user.need_two_factor_authentication?(request)
  end

  def update_active_sidebar_path
    sidebar_paths =
      [ips_path,
       certificates_path,
       memberships_path,
       new_organisation_settings_path,
       settings_path,
       new_logs_search_path,
       super_admin_locations_path,
       super_admin_organisations_path,
       super_admin_users_path,
       new_super_admin_allowlist_path,
       super_admin_wifi_user_search_path,
       super_admin_wifi_admin_search_path,
       super_admin_change_organisation_path]
    if sidebar_paths.include?(request.path)
      session[:sidebar_path] = request.path
    end
  end

  def subnav
    :default
  end

  def sidebar
    :default
  end

  def authorise_manage_locations
    redirect_to(root_path) unless current_user.can_manage_locations?(current_organisation)
  end
end
