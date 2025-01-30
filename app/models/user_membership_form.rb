class UserMembershipForm
  include ActiveModel::Model

  attr_accessor :name, :service_email, :organisation_name, :confirmation_token, :password

  def write_to(user)
    return false if user.confirmed?

    user.assign_attributes(name:, password:, confirmed_at: Time.zone.now.utc)
    user.organisations.build(name: organisation_name, service_email:)
    if user.valid?
      User.transaction do
        user.save!
        user.memberships.last.confirm!
      end
      true
    else
      copy_errors_from(user)
      false
    end
  end

private

  def copy_errors_from(user)
    attribute_transform_map = {
      "organisations.service_email": :service_email,
      "organisations.name": :organisation_name,
    }
    user.errors.each do |error|
      attribute = attribute_transform_map[error.attribute] || error.attribute
      errors.add(attribute, error.message)
    end
  end
end
