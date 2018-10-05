class LogsController < ApplicationController
  def index
    result = UseCases::Administrator::GetAuthRequestsForUsername.new(
      authentication_logs_gateway: Gateways::LoggingApi.new
    ).execute(username: params[:username])

    @logs = result
  end
end
