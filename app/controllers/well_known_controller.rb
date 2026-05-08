class WellKnownController < ApplicationController
  skip_before_action :authenticate_user!, only: [:security_txt]

  def security_txt
    redirect_to Rails.application.config.security_txt_url, allow_other_host: true, status: :moved_permanently
  end
end
