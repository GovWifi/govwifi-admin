FactoryBot.define do
  factory :session do
    sequence :siteIP do |n|
      fourth = n % 255
      third = n / 255
      "141.0.#{third}.#{fourth}"
    end
    task_id { "arn:12345" }
    success { true }
    start { (Time.zone.now - 1.day).to_s }
    cert_serial { Faker::Number.number(digits: 10) }
  end
end
