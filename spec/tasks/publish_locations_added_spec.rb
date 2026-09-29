# frozen_string_literal: true

require "rails_helper"
require "rake"

describe "metrics:publish_locations_added rake task" do
  before do
    Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)
    Rake::Task["metrics:publish_locations_added"]&.clear if Rake::Task.task_defined?("metrics:publish_locations_added")
    load File.expand_path("../../lib/tasks/publish_locations_added.rake", __dir__)
  end

  it "delegates to UseCases::Administrator::PublishLocationsAdded with the parsed date argument" do
    expect(UseCases::Administrator::PublishLocationsAdded).to receive(:execute).with(
      date: Date.new(2026, 7, 17),
      logger: anything,
    )

    Rake::Task["metrics:publish_locations_added"].reenable
    Rake::Task["metrics:publish_locations_added"].invoke("2026-07-17")
  end

  it "defaults date to Time.zone.today when no argument is supplied" do
    expect(UseCases::Administrator::PublishLocationsAdded).to receive(:execute).with(
      date: Time.zone.today,
      logger: anything,
    )

    Rake::Task["metrics:publish_locations_added"].reenable
    Rake::Task["metrics:publish_locations_added"].invoke
  end
end
