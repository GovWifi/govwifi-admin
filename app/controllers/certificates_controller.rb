class CertificatesController < ApplicationController
  before_action :authorise_manage_certificates
  before_action :authorise_manage_current_certificate, only: %i[show edit destroy update]
  before_action :cba_flag_check

  def index
    @certificates = Certificate.where(organisation: current_organisation)
  end

  def show
    @certificate = Certificate.find(params[:id])
    @confirm_remove = !params[:confirm_remove].nil?
    render :show
  end

  def edit
    @certificate = Certificate.find(params[:id])
  end

  def destroy
    @certificate = Certificate.find(params[:id])
    if @certificate.has_child?
      redirect_to(certificates_path, alert: t(".remove_children"))
    else
      @certificate.destroy!
      redirect_to(certificates_path, notice: t(".removed", name: @certificate.name))
    end
  end

  def update
    name = params.dig(:certificate, :name)

    @certificate = Certificate.find(params[:id])
    if @certificate.update(name:)
      redirect_to certificates_path, notice: t(".renamed")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def new
    @certificate_form = CertificateForm.new(organisation: current_organisation)
  end

  def create
    cert_params = params.require(:certificate_form).permit(:file, :name)
    file = cert_params[:file]
    name = cert_params[:name]

    @certificate_form = CertificateForm.new(name:, file:, organisation: current_organisation)
    if @certificate_form.save
      redirect_to(certificates_path, notice: t(".new_certificate", name: @certificate_form.name))
    else
      render :new, status: :unprocessable_content
    end
  end

private

  def authorise_manage_current_certificate
    unless can? :manage, Certificate.find(params[:id])
      redirect_to root_path, alert: t(".not_allowed")
    end
  end

  def authorise_manage_certificates
    redirect_to root_path, alert: t(".not_allowed") unless current_user.can_manage_certificates?(current_organisation)
  end

  def cba_flag_check
    redirect_to root_path, alert: t(".not_allowed") unless current_organisation.cba_enabled?
  end
end
