FactoryBot.define do
  factory :user do
    sequence :email do |n|
      "test#{n}@gov.uk"
    end
    password { '123456' }
    name { "bob" }
    confirmed_at { Time.zone.now }

    trait :super_admin do
      after(:create) do |user|
        create(:organisation, users: [user], super_admin: true)
      end
    end

    trait :with_organisation do
      after(:create) do |user|
        create(:organisation, users: [user])
      end
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end
  end
end
