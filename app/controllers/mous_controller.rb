class MousController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[handle_nomination_signature confirmation_of_signature]
  before_action :set_mou, only: %i[new choose_option handle_nomination_signature]
  before_action :set_nomination, only: :handle_nomination_signature

  def new; end

  def choose_option
    action = params[:chosen_action]
    if action == "sign_mou"
      render "sign_mou"
    elsif action == "nominate_user"
      render "nominate_user"
    else
      flash[:notice] = "Please choose an option to proceed."
      render :new
    end
  end

  def sign
    @mou = Mou.new(mou_params)
    if @mou.save
      flash[:success] = "MOU signed successfully."
      invalidate_nomination(@mou.organisation_id)
      send_thank_you_email(@mou)
      redirect_to settings_path, notice: "#{current_organisation.name} has accepted the MOU for GovWifi"
    else
      flash[:alert] = @mou.errors.full_messages.join(". ").to_s
      render "sign_mou"
    end
  end

  def handle_nomination_signature
    if @nomination.nil?
      flash[:notice] = "Invalid token."
      redirect_to root_path
    elsif request.post?
      nominee_params = mou_params.merge(user: current_user,
                                        organisation: @organisation,
                                        version: Mou.latest_version)
      @mou = Mou.new(nominee_params)
      if @mou.save
        flash[:success] = "MOU signed successfully."
        invalidate_nomination(@mou.organisation_id)
        send_thank_you_email(@mou)
        redirect_to confirmation_of_signature_path(organisation_id: @mou.organisation_id)
      else
        flash[:alert] = @mou.errors.full_messages.join(". ").to_s
        redirect_to nominee_form_for_mou_path(token: @token)
      end
    end
  end

  def confirmation_of_signature
    @organisation = Organisation.find(params[:organisation_id])
  end

private

  def set_mou
    @mou = Mou.new
  end

  def set_nomination
    @token = params[:token]
    @nomination = Nomination.find_by(nomination_token: @token) if @token.present?
    @organisation = @nomination&.organisation
  end

  def mou_params
    params.require(:mou).permit(:name, :email_address, :job_role, :signed, :token)
  end

  def find_organisation
    current_organisation || @organisation
  end

  def send_thank_you_email(mou)
    AuthenticationMailer.thank_you_for_signing_the_mou(
      mou.name,
      mou.email_address,
      mou.organisation.name,
      mou.created_at,
    ).deliver_now
  end

  def invalidate_nomination(organisation_id)
    nomination = Nomination.find_by(organisation_id:)
    nomination&.update!(nomination_token: nil)
  end
end
