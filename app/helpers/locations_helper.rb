module LocationsHelper
  def organisations_list
    current_user.is_super_admin? ? Organisation.all : current_user.organisations
  end
end
