class NotifyTemplates
  TEMPLATES = %w[
    confirmation_email
    reset_password_email
    unlock_account
    invite_email
    cross_organisation_invitation
    nominate_user_to_sign_mou
    thank_you_for_signing_the_mou
    first_ip_survey
    user_account_removed_email
    user_account_removed_sms
    account_health_no_signed_mou
  ].freeze

  def self.template_hash
    @template_hash ||= begin
      all_templates = Services.notify_gateway.get_all_templates.collection.inject({}) do |result, template|
        result.merge(template.name => template.id)
      end
      all_templates.slice(*TEMPLATES)
    end
  end

  def self.template(name)
    template_hash.fetch(name.is_a?(Symbol) ? name.to_s : name)
  end

  def self.verify_templates
    names = Services.notify_gateway.get_all_templates.collection.map(&:name)
    differences = NotifyTemplates::TEMPLATES - names
    raise "Some templates have not been defined in Notify: #{differences.join(', ')}" unless differences.empty?
  end
end
