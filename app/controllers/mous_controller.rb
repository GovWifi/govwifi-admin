class MousController < ApplicationController
  def show_options; end

  def choose_option
    action = params[:chosen_action]
    if action == "sign_mou"
      redirect_to new_mou_path
    elsif action == "nominate_user"
      redirect_to new_nomination_path
    else
      flash[:alert] = "Please choose an option to proceed"
      render :show_options, status: :unprocessable_content
    end
  end

  def new
    @mou_form = MouForm.new
  end

  def create
    @mou_form = MouForm.new(mou_params)
    if @mou_form.invalid?
      render :new
    else
      old_nomination = current_organisation.nomination
      old_nomination&.destroy!
      mou = @mou_form.save!(organisation: current_organisation, user: current_user)
      send_thank_you_email(mou)
      redirect_to settings_path, notice: "#{current_organisation.name} has accepted the MOU for GovWifi"
    end
  end

private

  def token
    params[:token] || params.dig(:mou, :token)
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
