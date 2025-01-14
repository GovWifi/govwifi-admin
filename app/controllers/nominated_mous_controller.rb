class NominatedMousController < ApplicationController
  skip_before_action :authenticate_user!, :redirect_user_with_no_organisation
  before_action :set_nomination, only: %i[new create]
  before_action :check_token, only: %i[new create]

  def new
    @token = token_from_params
    @mou_form = MouForm.new
  end

  def create
    @token = token_from_params
    @mou_form = MouForm.new(mou_params)
    if @mou_form.invalid?
      render :new
    else
      mou = @mou_form.save!(organisation: @nomination.organisation)
      @nomination.destroy!
      send_thank_you_email(mou)
      redirect_to confirm_nominated_mous_path(organisation_name: @nomination.organisation_name), success: "MOU signed successfully."
    end
  end

  def confirm
    @organisation_name = params[:organisation_name]
  end

private

  def check_token
    redirect_to root_path, error: "Invalid token." if @nomination.nil?
  end

  def token_from_params
    params[:token] || params.dig(:mou_form, :token)
  end

  def set_nomination
    @nomination = Nomination.find_by(token: token_from_params) if token_from_params.present?
  end

  def mou_params
    params.require(:mou_form).permit(:name, :email_address, :job_role, :signed)
  end

  def send_thank_you_email(mou)
    GovWifiMailer.thank_you_for_signing_the_mou(
      mou.name,
      mou.email_address,
      mou.organisation.name,
      mou.formatted_date,
    ).deliver_now
  end
end
