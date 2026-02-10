# frozen_string_literal: true

class TimeoutController < ApplicationController
  skip_before_action :authenticate_user!, only: :signed_out
  skip_before_action :confirm_two_factor_setup, only: :signed_out
  skip_before_action :redirect_user_with_no_organisation, only: :signed_out
  skip_before_action :update_active_sidebar_path

  # GET /timeout/keep_alive - called by HMRC timeout dialog when user clicks "Stay signed in"
  # Requires authentication so Devise touches the session and resets the timeout timer
  def keep_alive
    head :ok
  end

  # GET /timeout/signed_out - "We signed you out" page
  # Shown when the user is timed out (did nothing when the warning was displayed).
  # The HMRC dialog redirects here when the countdown reaches zero.
  def signed_out
    sign_out(current_user) if user_signed_in?
    render :signed_out, layout: "application"
  end
end
