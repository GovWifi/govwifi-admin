class LogsController < ApplicationController
  skip_before_action :redirect_user_with_no_organisation

  def index
    log_search_form = LogSearchForm.new(form_params)
    return render "logs_searches/new", locals: { log_search_form: } unless log_search_form.valid?

    success = log_search_form.success
    authentication_method = log_search_form.authentication_method

    case log_search_form.filter_option
    when LogSearchForm::LOCATION_FILTER_OPTION
      location = current_organisation.locations.find(log_search_form.location_id)
      logs = Gateways::Sessions.search(ips: location.ips.pluck(:address), success:)
      render locals: { log_search_form:,
                       location_address: location.address,
                       logs:,
                       table_data: build_table_data(log_search_form, logs) }
    when LogSearchForm::IP_FILTER_OPTION
      ips = if super_admin?
              log_search_form.ip
            else
              current_organisation.ip_addresses.intersection([log_search_form.ip])
            end

      logs = Gateways::Sessions.search(ips:, success:, authentication_method:)

      @current_location = Ip.find_by(address: ips).location if logs.present?
      render locals: { log_search_form:, logs:, table_data: build_table_data(log_search_form, logs) }
    when LogSearchForm::MAC_FILTER_OPTION
      ips = super_admin? ? nil : current_organisation.ip_addresses
      logs = Gateways::Sessions.search(ips:, mac: log_search_form.mac, success:)
      render locals: { log_search_form:, logs:, table_data: build_table_data(log_search_form, logs) }

    when LogSearchForm::USERNAME_FILTER_OPTION
      ips = super_admin? ? nil : current_organisation.ip_addresses
      logs = Gateways::Sessions.search(ips:, username: log_search_form.username, success:)
      render locals: { log_search_form:, logs:, table_data: build_table_data(log_search_form, logs) }
    end
  end

private

  def form_params
    params.require(:log_search_form)
      .permit(:filter_option, :ip, :username, :location_id, :success, :authentication_method, :mac)
      .transform_values(&:strip)
  rescue StandardError
    {}
  end

  def build_table_data(log_search_form, logs)
    headers = []
    columns = []
    if log_search_form.username.blank?
      headers << "Username or ID"
      columns << logs.map do |log|
        if log.username.blank?
          ""
        else
          helpers.govuk_link_to(log.username,
                                logs_path(log_search_form: { username: log.username, filter_option: LogSearchForm::USERNAME_FILTER_OPTION }))
        end
      end
    end
    if log_search_form.ip.present? && current_organisation&.cba_enabled?
      headers << "Authentication Method"
      headers << "Certificate Serial Number"
      columns << logs.map { |log| log.eap_tls? ? "EAP-TLS" : "MSCHAP" }
      columns << logs.map(&:cert_serial)
    end

    headers << "Access Point"
    columns << logs.map { |log| log.ap || "" }

    headers << "MAC Address"
    columns << logs.map do |log|
      if log.mac.blank?
        ""
      else
        helpers.govuk_link_to(
          log.mac,
          logs_path(log_search_form: { mac: log.mac, filter_option: LogSearchForm::MAC_FILTER_OPTION }),
        )
      end
    end
    if log_search_form.ip.nil?
      headers << "IP"
      columns << logs.map do |log|
        helpers.govuk_link_to(log.siteIP,
                              logs_path(log_search_form: { ip: log.siteIP, filter_option: LogSearchForm::IP_FILTER_OPTION }))
      end
    end

    headers << "Time (UTC)"
    columns << logs.map { |log| log.start.to_fs(:no_timezone) }

    headers << "Status"
    columns << logs.map { |log| log.success ? "successful" : "failed" }

    if super_admin?
      headers << "Radius Server task id"
      columns << logs.map(&:task_id)
    end

    { head: headers, rows: columns.transpose }
  end
end
