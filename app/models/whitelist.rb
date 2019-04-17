class Whitelist
  include ActiveModel::Model

  attr_accessor :email_domain, :organisation_name

  def save
    ActiveRecord::Base.transaction do
      CustomOrganisationName.create!(name: organisation_name) if organisation_name.present?
      AuthorisedEmailDomain.create!(name: email_domain) if email_domain.present?
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.message)

    false
  end
end
