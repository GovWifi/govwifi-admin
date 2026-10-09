# Linked from account health emails. Switches to the organisation in the link, if the user can
# access it, and opens the page where the issue can be fixed.
class AccountHealthLinksController < ApplicationController
  DESTINATIONS = {
    "no_signed_mou" => :show_options_mous_path,
    "missing_location_details" => :ips_path,
    "fewer_than_two_administrators" => :memberships_path,
    "inactive_administrator" => :memberships_path,
  }.freeze

  skip_before_action :redirect_user_with_no_organisation

  def show
    destination = DESTINATIONS[params[:issue]]
    return head :not_found if destination.nil?

    organisation_id = params[:organisation_id].to_i
    if current_user.confirmed_member_of?(organisation_id) || (super_admin? && Organisation.exists?(organisation_id))
      session[:organisation_id] = organisation_id
      redirect_to public_send(destination)
    else
      redirect_to root_path, alert: "You are not a member of the organisation in that link."
    end
  end
end
