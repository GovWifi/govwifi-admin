class Users::PasswordsController < Devise::PasswordsController
  append_before_action :validate_user_is_confirmed, only: :create # rubocop:disable Rails/LexicallyScopedActionFilter

protected

  def validate_user_is_confirmed
    user = User.find_by(email: params.dig(:user, :email))
    unless user.nil? || user.confirmed?
      set_flash_message(:alert, :unconfirmed)
      redirect_to new_user_confirmation_path
    end
  end
end
