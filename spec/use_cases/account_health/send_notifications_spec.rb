describe UseCases::AccountHealth::SendNotifications do
  include AccountHealthHelpers

  subject(:use_case) { described_class.new(logger:, enabled:, organisation_ids:) }

  let(:logger) { instance_double(Logger, info: nil, warn: nil, error: nil) }
  let(:enabled) { true }
  let(:organisation_ids) { nil }
  # Signed MoU, so it starts with no issues.
  let(:organisation) { create(:organisation).tap { |org| create(:mou, organisation: org) } }
  let!(:admin) { add_member(organisation) }
  let!(:second_admin) { add_member(organisation) }

  around { |example| Timecop.freeze(Time.zone.local(2026, 9, 25, 9)) { example.run } }

  before { allow_account_health_organisation_names }

  # Ignores other emails, such as Devise confirmation emails sent when creating unconfirmed users.
  def sent_emails
    Services.notify_gateway.email_parameters.select { |email| email[:reference].start_with?("account_health_") }
  end

  def remove_mou
    Mou.where(organisation:).delete_all
  end

  it "emails every administrator with the template's placeholders" do
    remove_mou

    use_case.execute

    expect(sent_emails).to contain_exactly(*[admin, second_admin].map do |user|
      {
        email_address: user.email,
        personalisation: {
          organisation: organisation.name,
          action_url: "https://example.com/account_health/#{organisation.id}/no_signed_mou",
        },
        template_id: "account_health_no_signed_mou_template",
        reference: "account_health_no_signed_mou",
      }
    end)
  end

  it "emails only confirmed users with accepted administrator memberships" do
    remove_mou
    add_member(organisation, accepted: false)
    add_member(organisation, confirmed_user: false)
    add_member(organisation, permissions: :view_only)

    use_case.execute

    expect(sent_emails.map { |e| e[:email_address] }).to contain_exactly(admin.email, second_admin.email)
  end

  it "emails everyone who can manage locations about locations missing details" do
    location_manager = add_member(organisation, permissions: :manage_locations)
    add_location_with_ip(organisation, address: "", postcode: "")

    use_case.execute

    expect(sent_emails.map { |e| e[:email_address] }).to contain_exactly(admin.email, second_admin.email, location_manager.email)
    expect(sent_emails.map { |e| e[:reference] }.uniq).to eq(%w[account_health_missing_location_details])
  end

  it "emails once per issue, and again only if it recurs after being fixed" do
    remove_mou
    2.times { use_case.execute }
    expect(sent_emails.size).to eq(2)

    create(:mou, organisation:)
    use_case.execute
    expect(organisation.account_health_notifications.sole.resolved_at).to be_present

    remove_mou
    use_case.execute
    expect(sent_emails.size).to eq(4)
  end

  it "records an organisation with nobody to email, and emails an administrator who joins later" do
    remove_mou
    organisation.memberships.destroy_all

    use_case.execute
    expect(sent_emails).to be_empty
    expect(organisation.account_health_notifications.sole.uncontactable_at).to be_present

    new_admin = add_member(organisation)
    use_case.execute
    expect(sent_emails.map { |e| e[:email_address] }).to eq([new_admin.email])
  end

  it "retries a failed email on the next run" do
    remove_mou
    allow(Services.notify_gateway).to receive(:send_email).and_call_original
    allow(Services.notify_gateway).to receive(:send_email)
      .with(hash_including(email_address: admin.email)).and_raise(StandardError, "Notify unavailable")

    use_case.execute
    expect(AccountHealthNotificationRecipient.find_by(user: admin))
      .to have_attributes(sent_at: nil, attempts: 1, last_error: "StandardError: Notify unavailable")

    allow(Services.notify_gateway).to receive(:send_email).and_call_original
    use_case.execute
    expect(sent_emails.map { |e| e[:email_address] }).to contain_exactly(admin.email, second_admin.email)
  end

  it "does not send an email that an overlapping run has already sent" do
    remove_mou
    use_case.execute
    recipient = AccountHealthNotificationRecipient.find_by(user: admin)
    recipient.update!(sent_at: nil, attempts: 0)
    stale_copy = AccountHealthNotificationRecipient.find(recipient.id)
    recipient.update!(sent_at: Time.zone.now, attempts: 1)

    expect { use_case.send(:deliver, stale_copy) }.not_to(change { sent_emails.size })
  end

  context "when limited to some organisations" do
    let(:organisation_ids) { [organisation.id] }

    it "records and emails only those organisations" do
      remove_mou
      create(:organisation).tap { |org| add_member(org) }

      use_case.execute

      expect(AccountHealthNotification.distinct.pluck(:organisation_id)).to eq([organisation.id])
    end
  end

  context "when disabled" do
    let(:enabled) { false }

    it "only logs what it would send" do
      remove_mou

      use_case.execute

      expect(sent_emails).to be_empty
      expect(AccountHealthNotification.count).to eq(0)
      expect(logger).to have_received(:info).with("Account health (dry run): no_signed_mou: 1 organisations, 2 recipients, 0 with nobody to email")
    end
  end

  it "is disabled unless ACCOUNT_HEALTH_EMAILS_ENABLED is 'true'" do
    original = ENV["ACCOUNT_HEALTH_EMAILS_ENABLED"]
    ENV.delete("ACCOUNT_HEALTH_EMAILS_ENABLED")
    expect(described_class.enabled?).to be(false)
    ENV["ACCOUNT_HEALTH_EMAILS_ENABLED"] = "true"
    expect(described_class.enabled?).to be(true)
  ensure
    ENV["ACCOUNT_HEALTH_EMAILS_ENABLED"] = original
  end
end
