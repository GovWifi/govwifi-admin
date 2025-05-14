module SettingsHelper
  def organisation_data(current_organisation)
    [
      {
        key: { text: "Service email" },
        value: { text: current_organisation.service_email },
        actions: [
          {
            text: "Change",
            href: edit_organisation_path(current_organisation.id),
            visually_hidden_text: "service email",
          },
        ],
      },
      {
        key: { text: "Memorandum of understanding (MOU)" },
        value: { text: mou_status_label(current_organisation) },
        actions: [mou_action(current_organisation)],
      },
    ]
  end

  def mou_status_label(current_organisation)
    last_mou = current_organisation.mous.last

    return "Signed by #{last_mou.name} on #{last_mou.formatted_date}" if last_mou&.name.present?

    return "#{current_organisation.name} signed the GovWifi MOU" if last_mou.present?

    label = content_tag(:span, class: "govuk-!-font-weight-bold") { "Not signed" }
    label += if current_organisation.nomination&.name
               content_tag(:p, class: "govuk-body") do
                 "#{current_organisation.nomination.name} has been nominated to sign the MOU"
               end
             else
               sign_mou_label
             end
    label
  end

  def mou_action(current_organisation)
    if current_organisation.mous.present?
      return { text: "Sign the MOU", href: show_options_mous_path } if current_organisation.resign_mou?

      {
        text: "Review",
        href: "https://www.wifi.service.gov.uk/memorandum-of-understanding/",
        visually_hidden_text: "memorandum of understanding",
      }
    else
      { text: "Sign the MOU", href: show_options_mous_path }
    end
  end

  def sign_mou_label
    label = content_tag(:p, class: "govuk-body") do
      "A GovWifi admin from your organisation or someone nominated by your organisation must sign the MOU for your organisation to use GovWifi."
    end
    inset_text = govuk_inset_text do
      "A GovWifi admin is someone who manages GovWifi on behalf of your organisation."
    end
    label + inset_text
  end

  def radius_ip_list(ips)
    govuk_list(ips.map { |ip| format_ip(ip) })
  end
end
