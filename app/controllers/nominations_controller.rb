class NominationsController < ApplicationController
  def new
    @nomination = Nomination.new
  end

  def create
    mou_params = params.require(:nomination).permit(:name, :email)
    old_nomination = current_organisation.nomination

    @nomination = Nomination.new(mou_params.merge(nominated_by: current_user.name,
                                                  token: generate_token,
                                                  organisation: current_organisation))
    if @nomination.valid?
      old_nomination&.destroy!
      @nomination.save!
      send_nomination_email(@nomination.name,
                            @nomination.email,
                            @nomination.nominated_by,
                            @nomination.token)
      redirect_to what_happens_next_mous_path, notice: "You nominated #{@nomination.name} to sign the GovWifi MOU"
    else
      render :new
    end
  end

private

  def generate_token
    Devise.friendly_token[0, 20]
  end

  def send_nomination_email(name, email, nominated_by, token)
    GovWifiMailer.nomination_instructions(
      name,
      email,
      nominated_by,
      current_organisation.name,
      token,
    ).deliver_now
  end
end
