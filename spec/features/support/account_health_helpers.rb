module AccountHealthHelpers
  # The factory names organisations "Gov Org <n>" and validates them against the register.
  def allow_account_health_organisation_names
    stub_const("Gateways::GovukOrganisationsRegisterGateway::GOVERNMENT_ORGS", (1..30).map { |n| "Gov Org #{n}" }.freeze)
  end

  # Adds a member with accepted membership. permissions: :administrator, :manage_locations or :view_only.
  def add_member(organisation, accepted: true, permissions: :administrator, confirmed_user: true)
    user = create(:user, confirmed_at: (confirmed_user ? 1.month.ago : nil))
    create(:membership, organisation:, user:,
                        confirmed_at: (accepted ? 1.month.ago : nil),
                        can_manage_team: permissions == :administrator,
                        can_manage_locations: permissions != :view_only)
    user
  end

  def add_location_with_ip(organisation, address: "1 High Street", postcode: "SW1A 1AA")
    location = create(:location, organisation:)
    create(:ip, location:)
    location.update_columns(address:, postcode:)
    location.reload
  end
end
