module HelpHelper
  def individual_troubleshoot_list(current_organisation)
    result = ["direct them to #{govuk_link_to 'our guidance on common issues', SITE_CONFIG['end_user_troubleshooting_link']}".html_safe]
    unless current_organisation&.locations&.empty?
      result << "#{govuk_link_to 'search our logs', new_logs_search_path} to confirm they are reaching our service".html_safe
    end
    result << "check the #{govuk_link_to 'GovWifi service status', SITE_CONFIG['service_status_link']}.".html_safe
  end

  def organisation_troubleshoot_list(current_organisation)
    result = ["check your #{govuk_link_to 'IP addresses and RADIUS secret keys', ips_path} match your local configuration".html_safe]
    unless current_organisation&.locations&.empty?
      result << "#{govuk_link_to 'search our logs', new_logs_search_path} to confirm traffic from you is reaching our service".html_safe
    end
    result << "search #{govuk_link_to 'our technical documentation', SITE_CONFIG['organisation_docs_link']}".html_safe
    result << "check the #{govuk_link_to 'GovWifi service status', SITE_CONFIG['service_status_link']}".html_safe
  end
end
