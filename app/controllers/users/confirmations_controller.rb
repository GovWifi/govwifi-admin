class Users::ConfirmationsController < Devise::ConfirmationsController
  # This controller overrides the Devise:ConfirmationsController (part of Devise gem)
  # in order to set user passwords after they have confirmed their email. This is
  # based largely on recommendations here: 'https://github.com/plataformatec/devise/wiki/How-To:-Override-confirmations-so-users-can-pick-their-own-passwords-as-part-of-confirmation-activation'
  before_action :set_user, only: %i[update show]
  before_action :ensure_user_not_confirmed, only: %i[update show]
  before_action :fetch_organisations_from_register, only: %i[update show]
  after_action :publish_organisation_names, only: :update

  def new; end

  def create
    User.send_confirmation_instructions(email: params[:email])
    set_flash_message! :notice, :send_paranoid_instructions
    redirect_to after_resending_confirmation_instructions_path_for(User)
  end

  def show
    params = token_params.empty? ? form_params : token_params
    @form = UserMembershipForm.new(params)
  end

  def update
    @form = UserMembershipForm.new(form_params)
    if @form.write_to(@user)
      set_flash_message :notice, :confirmed
      sign_in_and_redirect(resource_name, @user)
    else
      render :show
    end
  end

  def pending; end

protected

  def set_user
    @user = User.find_or_initialize_with_error_by(:confirmation_token, token_params[:confirmation_token] || form_params[:confirmation_token])
  end

  def ensure_user_not_confirmed
    if @user.confirmed?
      flash[:alert] = "Email was already confirmed"
      redirect_to root_path
    end
  end

  def token_params
    params.permit(:confirmation_token)
  end

  def form_params
    params.require(:user_membership_form).permit(:name, :password, :organisation_name, :service_email, :confirmation_token)
  end

private

  def fetch_organisations_from_register
    @register_organisations = Organisation.fetch_organisations_from_register
  end

  def publish_organisation_names
    UseCases::Administrator::PublishOrganisationNames.new.publish
  end
end
