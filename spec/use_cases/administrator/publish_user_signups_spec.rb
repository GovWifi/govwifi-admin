# frozen_string_literal: true

require "rails_helper"

describe UseCases::Administrator::PublishUserSignups do
  let(:today) { Date.parse("2026-07-17") }
  let(:logger) { instance_double(Logger, info: nil, warn: nil) }

  subject(:use_case) { described_class.new(date: today, logger:) }

  it "calls to_s3 and to_api on UserSignupsMetricSender for all six signup metrics" do
    sender_double = instance_double(
      Performance::Metrics::UserSignupsMetricSender,
      key: "test-key",
      to_s3: nil,
      to_api: nil,
    )

    Performance::Metrics::UserSignupsMetricSender::STATS.each_key do |metric|
      expect(Performance::Metrics::UserSignupsMetricSender).to receive(:new).with(
        date: today,
        metric:,
        logger:,
      ).and_return(sender_double)
    end

    expect(sender_double).to receive(:to_s3).exactly(6).times
    expect(sender_double).to receive(:to_api).exactly(6).times

    use_case.publish
  end

  it "supports .execute class method delegation" do
    sender_double = instance_double(
      Performance::Metrics::UserSignupsMetricSender,
      key: "test-key",
      to_s3: nil,
      to_api: nil,
    )

    allow(Performance::Metrics::UserSignupsMetricSender).to receive(:new).and_return(sender_double)
    expect(sender_double).to receive(:to_s3).exactly(6).times
    expect(sender_double).to receive(:to_api).exactly(6).times

    described_class.execute(date: today, logger:)
  end

  it "accepts a string date and parses it into a Date object" do
    use_case_with_string = described_class.new(date: "2026-07-17", logger:)
    sender_double = instance_double(
      Performance::Metrics::UserSignupsMetricSender,
      key: "test-key",
      to_s3: nil,
      to_api: nil,
    )

    allow(Performance::Metrics::UserSignupsMetricSender).to receive(:new).with(
      date: today,
      metric: anything,
      logger:,
    ).and_return(sender_double)

    use_case_with_string.publish
  end
end
