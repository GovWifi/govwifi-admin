class ContentSecurityPolicyController < ApplicationController
  protect_from_forgery with: :null_session

  def csp_violation_report
    # Log the CSP violation report for further analysis
    Rails.logger.info("CSP Violation Report: #{request.body.read}")

    head :no_content
  end
end
