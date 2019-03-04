# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :validate_email_on_whitelist, only: :create

protected

  # The path used after sign up for inactive accounts.
  def after_inactive_sign_up_path_for(_resource)
    users_confirmations_pending_path
  end

  def validate_email_on_whitelist
    gateway = Gateways::S3.new(
      bucket: ENV.fetch('S3_SIGNUP_WHITELIST_BUCKET'),
      key: ENV.fetch('S3_SIGNUP_WHITELIST_OBJECT_KEY')
    )
    checker = UseCases::Administrator::CheckIfWhitelistedEmail.new(gateway: gateway)
    whitelisted = checker.execute(sign_up_params[:email])[:success]

    if whitelisted == false
      logger.info("Unsuccessful signup attempt: #{sign_up_params[:email]}")
    end

    set_user_object_with_errors && return_user_to_registration_page unless whitelisted
  end

  def set_user_object_with_errors
    @user = User.new(sign_up_params)
    @user.errors.add(:email, 'must be from a government domain')
  end

  def return_user_to_registration_page
    render :new, resource: @user
  end
end
