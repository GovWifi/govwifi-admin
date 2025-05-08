module ApplicationHelper
  include ActionView::Helpers::OutputSafetyHelper

  def field_error(resource, key)
    resource&.errors&.include?(key.to_sym) ? "govuk-form-group--error" : ""
  end

  def input_error(resource, key)
    resource&.errors&.include?(key.to_sym) ? "govuk-input--error" : ""
  end

  def active_tab(path)
    classes = %w[govuk-link govuk-link--no-visited-state]
    classes << "active" if session[:sidebar_path] == path
    classes.join(" ")
  end

  def infer_page_title
    safe_join([content_for(:page_title), SITE_CONFIG["default_page_title"]].reject(&:nil?), " - ")
  end

  def format_ip(ip)
    content_tag(:span, class: "ip-address") do
      ip.scan(/\d{1,3}/).join(content_tag(:span, ".", class: "ip-address-separator")).html_safe
    end
  end
end
