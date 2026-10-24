class CustomOrganisationName < ApplicationRecord
  validate :custom_org_in_register?
  validates :name, presence: true

  before_validation :squish_name

  def squish_name
    self.name = name.to_s.squish
  end

  def custom_org_in_register?
    if Organisation.fetch_organisations_from_register.include?(name.strip)
      errors.add(:name, "Name is already in our register")
    end
  end
end
