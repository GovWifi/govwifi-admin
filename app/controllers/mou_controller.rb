class MouController < ApplicationController
  def index
    @mou = AdminConfig.mou.unsigned_document.attachment
    @current_org_signed_mou = current_organisation.signed_mou.attachment
  end

  def create
    if params[:signed_mou]
      current_organisation.signed_mou.attach(params[:signed_mou])
      flash[:notice] = "MOU uploaded successfully."
    else
      flash[:alert] = "Choose a file before uploading "
    end
    redirect_to mou_index_path
  end
end
