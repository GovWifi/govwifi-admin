FactoryBot.define do
  factory :account_health_notification do
    organisation
    issue { "no_signed_mou" }
    open_key { "#{organisation.id}:#{issue}" }
    detected_at { Time.zone.now }
  end
end
