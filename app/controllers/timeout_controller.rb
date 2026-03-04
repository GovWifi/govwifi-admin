class TimeoutController < ApplicationController
  skip_before_action :update_active_sidebar_path

  # GET /timeout/keep_alive - called when user clicks "Stay signed in"
  # Requires authentication so Devise touches the session and resets the timeout timer
  def keep_alive
    head :ok
  end

  # GET /timeout/sign_out - only used when HMRC countdown ends (to show session expired message)
  def sign_out_action
    sign_out(current_user)
    flash[:timedout] = true
    redirect_to new_user_session_path
  end
end
