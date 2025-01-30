FactoryBot.define do
  factory :user do
    transient do
      first_name { Faker::Name.first_name }
      last_name { Faker::Name.last_name }
    end
    email { "#{first_name}.#{last_name}@example.gov.uk" }
    password { "strong lemonade 1475 p4o6d09" }
    name { "#{first_name} #{last_name}" }
    confirmed_at { Time.zone.now }
    sent_first_ip_survey { true }

    trait :super_admin do
      is_super_admin { true }
    end

    trait :with_unconfirmed_membership do
      after(:create) do |user|
        create(:membership, :unconfirmed, user:, organisation: create(:organisation))
        user.reload
      end
    end

    trait :confirm_all_memberships do
      after(:create) do |user|
        user.memberships.each do |membership|
          membership.confirm! unless membership.confirmed?
        end
      end
    end

    trait :skip_notification do
      after(:build, &:skip_confirmation_notification!)
    end

    trait :with_organisation do
      after(:create) do |user|
        create(:membership, :confirmed, user:, organisation: create(:organisation))
        user.reload
      end
    end

    trait :with_organisation_and_locations do
      after(:create) do |user|
        create(:membership, :confirmed, user:, organisation: create(:organisation, :with_locations))
        user.reload
      end
    end

    trait :with_2fa do
      otp_secret_key { "ABCDEFGHIJKLMNOPQRSTUVWXYZ" } # 2FA is set up
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end
  end
end
