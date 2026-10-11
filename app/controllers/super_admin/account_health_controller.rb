class SuperAdmin::AccountHealthController < SuperAdminController
  def index
    @entries = UseCases::AccountHealth::Worklist.new.entries.select(&:listed?)
  end
end
