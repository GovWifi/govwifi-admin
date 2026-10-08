describe UseCases::AccountHealth::Worklist do
  include AccountHealthHelpers

  subject(:entries) { described_class.new.entries }

  let(:now) { Time.zone.local(2026, 10, 8, 12) }

  around { |example| Timecop.freeze(now) { example.run } }

  before { allow_account_health_organisation_names }

  def entry_for(organisation)
    entries.find { |entry| entry.organisation == organisation }
  end

  # An organisation whose only issue is no signed MoU, notified at sent_at.
  def unsigned_organisation(sent_at:, attempts: 1)
    organisation = create(:organisation).tap { |org| 2.times { add_member(org) } }
    create(:account_health_notification, organisation:, detected_at: sent_at || now)
      .recipients.create!(email_address: "admin@gov.uk", sent_at:, attempts:)
    organisation
  end

  it "uses calendar months from the first notification: under one, one to three inclusive, and over three" do
    expect(described_class.email_age_status(now - 1.month + 1.minute, now:)).to eq(:recently_notified)
    expect(described_class.email_age_status(now - 1.month, now:)).to eq(:follow_up_due)
    expect(described_class.email_age_status(now - 3.months, now:)).to eq(:follow_up_due)
    expect(described_class.email_age_status(now - 3.months - 1.minute, now:)).to eq(:overdue)
  end

  it "lists organisations we cannot reach first, then the longest outstanding, leaving out those not notified yet" do
    recent = unsigned_organisation(sent_at: now - 1.week)
    overdue = unsigned_organisation(sent_at: now - 6.months)
    failed = unsigned_organisation(sent_at: nil, attempts: AccountHealthNotificationRecipient::MAX_ATTEMPTS)
    no_administrators = create(:organisation)
    not_notified = create(:organisation).tap { |org| 2.times { add_member(org) } }

    expect(entries.select(&:listed?).map(&:organisation)).to eq([no_administrators, failed, overdue, recent])
    expect(entry_for(not_notified).listed?).to be(false)
  end

  it "checks each issue separately, so a location manager can still be notified about locations" do
    organisation = create(:organisation)
    add_member(organisation, permissions: :manage_locations)
    add_location_with_ip(organisation, address: "", postcode: "")

    statuses = entry_for(organisation).lines.to_h { |line| [line.issue, line.status] }

    expect(statuses).to eq("no_signed_mou" => :cannot_notify, "fewer_than_two_administrators" => :cannot_notify, "missing_location_details" => :not_emailed)
  end

  it "only uses an inactive administrator's own notification date" do
    organisation = create(:organisation).tap { |org| create(:mou, organisation: org) && add_member(org) }
    notified = add_member(organisation, signed_in_at: 2.years.ago)
    add_member(organisation, signed_in_at: 2.years.ago)
    create(:account_health_notification, organisation:, issue: "inactive_administrator", detected_at: now - 4.months)
      .recipients.create!(email_address: notified.email, user: notified, sent_at: now - 4.months, attempts: 1)

    expect(entry_for(organisation).issues.map(&:first_notified_at)).to contain_exactly(now - 4.months, nil)
  end

  it "drops issues as soon as they are fixed" do
    organisation = unsigned_organisation(sent_at: now - 4.months)
    create(:mou, organisation:)

    expect(entry_for(organisation)).to be_nil
  end
end
