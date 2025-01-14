class MonitoringController < ApplicationController
  skip_before_action :authenticate_user!, :redirect_user_with_no_organisation

  def healthcheck
    render body: "Healthy"
  end
end
