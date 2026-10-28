class Allowlist
  FIRST = "first".freeze
  SECOND = "second".freeze
  THIRD = "third".freeze
  FOURTH = "fourth".freeze
  FIFTH = "fifth".freeze
  SIXTH = "sixth".freeze

  PAGES = Set[FIRST, SECOND, THIRD, FOURTH, FIFTH, SIXTH].freeze

  include ActiveModel::Model

  attr_accessor :email_domain, :admin, :register, :organisation_name, :step

  def organisation_display_name
    organisation_name.to_s.squish
  end

  validate :validate_organisation_name, unless: proc { |allowlist|
    allowlist.organisation_name.blank?
  }
  validate :validate_email_domain, unless: proc { |allowlist| allowlist.email_domain.blank? }

  def next_step
    PAGES === step ? step : FIRST
  end

  def validate_organisation_name
    name = CustomOrganisationName.new(name: organisation_name)
    if name.invalid?
      name.errors.where(:name).each { |error| errors.import(error, attribute: :organisation_name) }
      self.step = FOURTH
    end
  end

  def validate_email_domain
    domain = AuthorisedEmailDomain.new(name: email_domain)
    if domain.invalid?
      domain.errors.where(:name).each { |error| errors.import(error, attribute: :email_domain) }
      self.step = FIFTH
    end
  end

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
