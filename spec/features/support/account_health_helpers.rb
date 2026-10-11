module AccountHealthHelpers
  # The factory names organisations "Gov Org <n>" and validates them against the register.
  def allow_account_health_organisation_names
    stub_const("Gateways::GovukOrganisationsRegisterGateway::GOVERNMENT_ORGS", (1..30).map { |n| "Gov Org #{n}" }.freeze)
  end

  # Adds a member with accepted membership. permissions: :administrator or :view_only.
  def add_member(organisation, accepted: true, permissions: :administrator, confirmed_user: true)
    user = create(:user, confirmed_at: (confirmed_user ? 1.month.ago : nil))
    create(:membership, organisation:, user:,
                        confirmed_at: (accepted ? 1.month.ago : nil),
                        can_manage_team: permissions == :administrator,
                        can_manage_locations: permissions == :administrator)
    user
  end
end
