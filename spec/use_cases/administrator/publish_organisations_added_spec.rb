# frozen_string_literal: true

require "rails_helper"

describe UseCases::Administrator::PublishOrganisationsAdded do
  let(:today) { Date.parse("2026-07-17") }
  let(:logger) { instance_double(Logger, info: nil, warn: nil) }

  subject(:use_case) { described_class.new(date: today, logger:) }

  it "calls to_s3 and to_api on OrganisationsAddedMetricSender for each metric" do
    sender_double = instance_double(
      Performance::Metrics::OrganisationsAddedMetricSender,
      key: "test-key",
      to_s3: nil,
      to_api: nil,
    )

    expect(Performance::Metrics::OrganisationsAddedMetricSender).to receive(:new).with(
      date: today,
      metric: :monthly_rolling_organisations_added,
      logger:,
    ).and_return(sender_double)

    expect(Performance::Metrics::OrganisationsAddedMetricSender).to receive(:new).with(
      date: today,
      metric: :month_to_date_organisations_added,
      logger:,
    ).and_return(sender_double)

    expect(sender_double).to receive(:to_s3).twice
    expect(sender_double).to receive(:to_api).twice

    use_case.publish
  end

  it "accepts a string date and parses it into a Date object" do
    use_case_with_string = described_class.new(date: "2026-07-17", logger:)
    sender_double = instance_double(
      Performance::Metrics::OrganisationsAddedMetricSender,
      key: "test-key",
      to_s3: nil,
      to_api: nil,
    )

    allow(Performance::Metrics::OrganisationsAddedMetricSender).to receive(:new).with(
      date: today,
      metric: anything,
      logger:,
    ).and_return(sender_double)

    use_case_with_string.publish
  end
end
