require "rails_helper"
require "rake"

describe "account_health:send_notifications rake task" do
  before do
    Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)
    Rake::Task["account_health:send_notifications"]&.clear if Rake::Task.task_defined?("account_health:send_notifications")
    load File.expand_path("../../lib/tasks/send_account_health_notifications.rake", __dir__)
  end

  it "delegates to UseCases::AccountHealth::SendNotifications" do
    use_case_double = instance_double(UseCases::AccountHealth::SendNotifications, execute: nil)

    expect(UseCases::AccountHealth::SendNotifications).to receive(:new).with(logger: anything).and_return(use_case_double)
    expect(use_case_double).to receive(:execute)

    Rake::Task["account_health:send_notifications"].reenable
    Rake::Task["account_health:send_notifications"].invoke
  end
end
