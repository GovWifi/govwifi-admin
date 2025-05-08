module CertificatesHelper
  def certificate_type_label(certificate)
    certificate.root_cert? ? "Root" : "Intermediate"
  end

  def available_label(certificate)
    certificate.created_at.today? ? "Available from 6am tomorrow" : nil
  end

  def certificate_expiry_label(certificate)
    expiry = if certificate.expired?
               content_tag(:strong, "Expired", class: "govuk-tag--red")
             elsif certificate.nearly_expired?(14)
               content_tag(:strong, "Expiring soon", class: "govuk-tag--orange")
             elsif certificate.not_yet_valid?
               content_tag(:strong, "Not yet valid", class: "govuk-tag--yellow")
             else
               ""
             end
    "#{certificate.not_after.strftime('%d %b %y')} #{expiry}".html_safe
  end
end
