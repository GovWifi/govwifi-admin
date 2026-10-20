# frozen_string_literal: true

require "rails_helper"
require "rake"

describe "metrics:publish_user_signups rake task" do
  before do
    Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)
    Rake::Task["metrics:publish_user_signups"]&.clear if Rake::Task.task_defined?("metrics:publish_user_signups")
    load File.expand_path("../../lib/tasks/publish_user_signups.rake", __dir__)
  end

  it "delegates to UseCases::Administrator::PublishUserSignups with the date argument" do
    use_case_double = instance_double(UseCases::Administrator::PublishUserSignups, publish: nil)

    expect(UseCases::Administrator::PublishUserSignups).to receive(:new).with(
      date: "2026-07-17",
      logger: anything,
    ).and_return(use_case_double)

    expect(use_case_double).to receive(:publish)

    Rake::Task["metrics:publish_user_signups"].reenable
    Rake::Task["metrics:publish_user_signups"].invoke("2026-07-17")
  end

  it "defaults date to Time.zone.today when no argument is supplied" do
    use_case_double = instance_double(UseCases::Administrator::PublishUserSignups, publish: nil)

    expect(UseCases::Administrator::PublishUserSignups).to receive(:new).with(
      date: Time.zone.today.to_s,
      logger: anything,
    ).and_return(use_case_double)

    expect(use_case_double).to receive(:publish)

    Rake::Task["metrics:publish_user_signups"].reenable
    Rake::Task["metrics:publish_user_signups"].invoke
  end
end
