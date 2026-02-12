class TimeoutController < ApplicationController
  skip_before_action :update_active_sidebar_path

  # GET /timeout/keep_alive - called when user clicks "Stay signed in"
  # Requires authentication so Devise touches the session and resets the timeout timer
  def keep_alive
    head :ok
  end
end
