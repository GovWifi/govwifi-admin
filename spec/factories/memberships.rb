FactoryBot.define do
  factory :membership

  trait :confirmed do
    confirmed_at { Time.zone.now }
  end

  trait :unconfirmed do
    confirmed_at { nil }
  end
end
