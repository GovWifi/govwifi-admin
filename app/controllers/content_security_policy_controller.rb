class ContentSecurityPolicyController < ActionController::Base
  protect_from_forgery with: :null_session

  def csp_violation_report
    # Log the CSP violation report for further analysis
    Rails.logger.warn("CSP Violation Report: #{request.body.read}")

    head :no_content
  end
end
