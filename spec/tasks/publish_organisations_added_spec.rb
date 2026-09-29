# frozen_string_literal: true

require "rails_helper"
require "rake"

describe "metrics:publish_organisations_added rake task" do
  before do
    Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)
    Rake::Task["metrics:publish_organisations_added"]&.clear if Rake::Task.task_defined?("metrics:publish_organisations_added")
    load File.expand_path("../../lib/tasks/publish_organisations_added.rake", __dir__)
  end

  it "delegates to UseCases::Administrator::PublishOrganisationsAdded with the date argument" do
    use_case_double = instance_double(UseCases::Administrator::PublishOrganisationsAdded, publish: nil)

    expect(UseCases::Administrator::PublishOrganisationsAdded).to receive(:new).with(
      date: "2026-07-17",
      logger: anything,
    ).and_return(use_case_double)

    expect(use_case_double).to receive(:publish)

    Rake::Task["metrics:publish_organisations_added"].reenable
    Rake::Task["metrics:publish_organisations_added"].invoke("2026-07-17")
  end

  it "defaults date to Time.zone.today when no argument is supplied" do
    use_case_double = instance_double(UseCases::Administrator::PublishOrganisationsAdded, publish: nil)

    expect(UseCases::Administrator::PublishOrganisationsAdded).to receive(:new).with(
      date: Time.zone.today.to_s,
      logger: anything,
    ).and_return(use_case_double)

    expect(use_case_double).to receive(:publish)

    Rake::Task["metrics:publish_organisations_added"].reenable
    Rake::Task["metrics:publish_organisations_added"].invoke
  end
end
