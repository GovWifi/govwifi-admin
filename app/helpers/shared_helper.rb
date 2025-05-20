module SharedHelper
  def ip_data(location, show_ip_controls)
    return [key: { text: "" }, value: { text: "No registered IP addresses" }] if location.sorted_ip_addresses.empty?

    location.sorted_ip_addresses.map do |ip|
      {
        key: { text: ip.address },
        value: { text: traffic_value(ip) },
        actions: ip_data_actions(ip, show_ip_controls),
      }
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
      result << { href: logs_path(log_search_form: { ip: ip.address, filter_option: LogSearchForm::IP_FILTER_OPTION }),
                  text: "View logs",
                  visually_hidden_text: "for IP address #{ip.address} at #{ip.location.full_address}" }
    end
    if show_ip_controls && current_user.can_manage_locations?(current_organisation)
      result << { href: ips_path(ip_id: ip.id, confirm_remove: true),
                  text: "Remove",
                  visually_hidden_text: "from #{ip.location.full_address}" }
    end
    result
  end
end
