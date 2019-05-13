class HelpController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :redirect_signed_in_user, only: :new

  def new
    case params[:choice]
    when "admin_account"
      redirect_to admin_account_new_help_path
    when "technical_support"
      redirect_to technical_support_new_help_path
    when "user_support"
      redirect_to user_support_new_help_path
    end
  end

  def technical_support
    @support_form = SupportForm.new
    @support_form.choice = :technical_support
  end

  def admin_account
    @support_form = SupportForm.new
    @support_form.choice = :admin_account
  end

  def user_support
    @support_form = SupportForm.new
    @support_form.choice = :user_support
  end

  def signed_in
    redirect_to new_help_path if current_user.nil?
    @support_form = SupportForm.new
    @support_form.choice = :signed_in
  end

  def create
    @support_form = SupportForm.new(support_form_params)

    if @support_form.email.blank?
      @support_form.email = current_user&.email
    end

    if @support_form.valid?
      if ENV['ZENDESK_API_ENDPOINT'].present?
        UseCases::Administrator::CreateSupportTicket.new(
          tickets_gateway: Gateways::ZendeskSupportTickets.new
        ).execute(
          requester: {
            email: sender_email,
            name: params[:support_form][:name] || current_user&.name,
            organisation: sender_organisation_name
          },
          details: params[:support_form][:details]
        )
      end

      redirect_to_homepage
    else
      render @support_form.choice
    end
  end

private

  def redirect_signed_in_user
    return redirect_to signed_in_new_help_path if current_user
  end

  def support_form_params
    params.require(:support_form).permit(:name, :details, :email, :organisation, :choice)
  end

  def redirect_to_homepage
    if current_user.nil?
      redirect_to new_user_session_path, notice: 'Your support request has been submitted.'
    else
      redirect_to root_path, notice: 'Your support request has been submitted.'
    end
  end

  def sender_email
    support_form_params[:email] || current_user&.email || ""
  end

  def sender_organisation_name
    support_form_params[:organisation] || current_user&.organisations&.first&.name || ""
  end
end
