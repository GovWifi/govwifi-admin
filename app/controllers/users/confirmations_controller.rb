class Users::ConfirmationsController < Devise::ConfirmationsController
  # This controller overrides the Devise:ConfirmationsController (part of Devise gem)
  # in order to set user passwords after they have confirmed their email. This is
  # based largely on recommendations here: 'https://github.com/plataformatec/devise/wiki/How-To:-Override-confirmations-so-users-can-pick-their-own-passwords-as-part-of-confirmation-activation'
  before_action :fetch_organisations_from_register, only: %i[update show]

  rescue_from UserMembershipForm::InvalidTokenError, with: :error_handler
  rescue_from UserMembershipForm::AlreadyConfirmedError, with: :error_handler

  # resend confirmation
  def new; end

  # resend confirmation
  def create
    User.send_confirmation_instructions(email: params[:email])
    set_flash_message! :notice, :send_paranoid_instructions
    redirect_to after_resending_confirmation_instructions_path_for(User)
  end

  # confirm user
  def show
    @form = UserMembershipForm.new(token_params.empty? ? form_params : token_params)
  end

  # confirm user
  def update
    @form = UserMembershipForm.new(form_params)
    if @form.save!
      set_flash_message :notice, :confirmed
      sign_in_and_redirect(resource_name, @form.user)
    else
      render :show
    end
  end

  def pending; end

protected

  def token_params
    params.permit(:confirmation_token)
  end

  def form_params
    params.require(:user_membership_form).permit(:name, :password, :organisation_name, :service_email, :confirmation_token)
  end

private

  def error_handler(exception)
    redirect_to new_user_session_path, alert: exception.message
  end

  def fetch_organisations_from_register
    @register_organisations = Organisation.fetch_organisations_from_register
  end
end
