class SettingsController < ApplicationController
  def review_mou
    return redirect_to(settings_path) if current_organisation.mous.empty?

    render :review_mou
  end

  def confirm_resign_mou
    return redirect_to(settings_path) if current_organisation.mous.empty?

    render :confirm_resign_mou
  end

  def resign_mou
    UseCases::Organisation::ResignMou.new(organisation_id: current_organisation.id).execute
    redirect_to show_options_mous_path,
                notice: "Your organisation must sign the memorandum of understanding again."
  end

  def index
    @ips = current_organisation.ips
    @locations = current_organisation.locations
    @team_members = current_organisation.users
    @london_radius_ips = radius_ips[:london]
    @dublin_radius_ips = radius_ips[:dublin]
  end

private

  def radius_ips
    view_radius = UseCases::Organisation::ViewRadiusIpAddresses.new(organisation_id: current_organisation.id)
    view_radius.execute
  end
end
