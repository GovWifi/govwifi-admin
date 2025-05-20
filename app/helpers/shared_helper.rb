module SharedHelper
  def ip_data(location, show_ip_controls)
    return [["", "No registered IP addresses", ""]] if location.sorted_ip_addresses.empty?

    location.sorted_ip_addresses.map do |ip|
      [ip.address, traffic_value(ip), govuk_list(ip_data_actions(ip, show_ip_controls), classes: %w[text-right])]
    end
  end

  def traffic_value(ip)
    if !ip.available?
      "Available at 6am tomorrow"
    elsif ip.unused?
      "No traffic received"
    elsif ip.inactive?
      "No traffic in the last 10 days"
    else
      "Receiving traffic"
    end
  end

  def ip_data_actions(ip, show_ip_controls)
    result = []
    if ip.available? && !ip.unused? && !ip.inactive?
      result << govuk_link_to("View logs",
                              logs_path(log_search_form: { ip: ip.address, filter_option: LogSearchForm::IP_FILTER_OPTION }),
                              visually_hidden_suffix: "for IP address #{ip.address} at #{ip.location.full_address}")
    end
    if show_ip_controls && current_user.can_manage_locations?(current_organisation)
      result << govuk_link_to("Remove",
                              ips_path(ip_id: ip.id, confirm_remove: true),
                              visually_hidden_suffix: "from #{ip.location.full_address}")
    end
    result
  end
end
