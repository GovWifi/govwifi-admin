# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
require "faker"
require "factory_bot"

FactoryBot.find_definitions

organisation = Organisation.create!(
  name: "UKTI Education", service_email: "it@parks.com",
)
empty_organisation = Organisation.create!(
  name: "Academy for Social Justice Commissioning", service_email: "empty@example.net",
)

FactoryBot.create(:user, :super_admin, email: "admin@gov.uk", password: "password")
FactoryBot.create(:user, :confirm_all_memberships, :super_admin,
                  email: "test@gov.uk", password: "password", organisations: [organisation, empty_organisation])

3.times do
  FactoryBot.create(:user, :confirm_all_memberships, organisations: [organisation])
end

2.times do
  FactoryBot.create(:user, :unconfirmed, organisations: [organisation])
end

# Location with no IP addresses
Location.create!(
  address: "The White Chapel Building, London",
  postcode: "E1 8QS",
  organisation_id: organisation.id,
)

FactoryBot.create_list(:location, 41, postcode: "AA11AA", organisation:)

location_one = Location.create!(
  address: "Momentum Centre, London",
  postcode: "SE1 0SX",
  organisation_id: organisation.id,
)

location_two = Location.create!(
  address: "136 Southwark Street, London",
  postcode: "E3 3EH",
  organisation_id: organisation.id,
)

10.times do
  Ip.create!(
    address: Faker::Internet.unique.public_ip_v4_address,
    location: location_one,
    created_at: [Time.zone.now, (Time.zone.now - 1.day)].sample,
  )
end

ip = FactoryBot.create(:ip, address: Faker::Internet.unique.public_ip_v4_address,
                            location: location_one,
                            created_at: Time.zone.now - 10.days)
FactoryBot.create_list(:session, 50,
                       success: true,
                       siteIP: ip.address,
                       start: Time.zone.now,
                       mac: Faker::Internet.mac_address,
                       ap: Faker::Internet.mac_address,
                       username: SecureRandom.alphanumeric(6).downcase)
FactoryBot.create_list(:session, 20,
                       success: false,
                       siteIP: ip.address,
                       start: Time.zone.now)

3.times do
  Ip.create!(
    address: Faker::Internet.unique.public_ip_v4_address,
    location: location_two,
  )
end

location_one.ips.each_with_index do |location_one_ip, index|
  Session.create(
    start: (Time.zone.now - (index + 5).day).to_s,
    success: index.even?,
    username: "Gerry",
    siteIP: location_one_ip.address,
  )
end

location_two.ips.each_with_index do |location_two_ip, index|
  Session.create(
    start: (Time.zone.now - index.day).to_s,
    success: index.even?,
    username: "Garry",
    siteIP: location_two_ip.address,
  )
end

Organisation.all.find_each do |org|
  org.update(cba_enabled: false)
end
