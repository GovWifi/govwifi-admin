FactoryBot.define do
  factory :membership

  trait :confirmed do
    confirmed_at { Time.zone.now }
  end

  trait :unconfirmed do
    confirmed_at { nil }
  end

  trait :administrator do
    can_manage_team { true }
    can_manage_locations { true }
  end

  trait :manage_locations do
    can_manage_team { false }
    can_manage_locations { true }
  end

  trait :view_only do
    can_manage_team { false }
    can_manage_locations { false }
  end
end
