require "warden"

def sign_up_for_account(email: "default@gov.uk")
  visit new_user_registration_path
  fill_in "Enter your email address", with: email
  click_on "Sign up"
end

def update_user_details(
  password: "actually1 strongPassw0rd !!",
  name: "bob",
  service_email: "admin@gov.uk",
  organisation_name: "Org 1"
)
  visit Services.notify_gateway.last_confirmation_url
  select organisation_name, from: "Organisation name"

  fill_in "Service email", with: service_email
  fill_in "Your name", with: name
  fill_in "Password", with: password
  click_on "Create my account"
end

def skip_two_factor_authentication
  Warden.on_next_request do |proxy|
    proxy.session(:user)[GovwifiTwoFactorAuth::NEED_AUTHENTICATION] = false
  end
end

def confirmation_email_link
  Services.notify_gateway.last_confirmation_url
end

def sign_in_user(user, pass_through_two_factor: true)
  user.confirm unless user.confirmed?
  login_as(user, scope: :user)

  skip_two_factor_authentication if pass_through_two_factor
end

def sign_out
  click_on "Sign out"
end

def user_is_a_member_of(organisation)
  visit(change_organisation_path)
  within(".govuk-list") do |list|
    expect(list).to have_content(organisation.name)
  end
end

def sign_in(email:, password:)
  totp_double = instance_double(ROTP::TOTP, provisioning_uri: "")
  allow(ROTP::TOTP).to receive(:new).and_return(totp_double)
  allow(totp_double).to receive(:verify).and_return(true)

  fill_in "Email", with: email
  fill_in "Password", with: password
  click_on "Continue"

  fill_in :code, with: "999999"
  click_on "Complete setup"

  visit root_path
end

def invite(email:, permission: "Administrator")
  visit new_users_invitation_path
  fill_in "Email address", with: email
  choose permission
  click_on "Send invitation email"
end
