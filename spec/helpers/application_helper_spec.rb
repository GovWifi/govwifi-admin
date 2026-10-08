require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  let(:title) { "some random title" }

  describe "#number_in_words" do
    it "spells out one to nine and uses numerals from 10" do
      expect([1, 3, 9, 10].map { |number| helper.number_in_words(number) }).to eq(%w[one three nine 10])
    end
  end

  describe "#infer_page_title" do
    let(:dummy) do
      Class.new do
        extend ApplicationHelper
        extend ActionView::Helpers::CaptureHelper
      end
    end

    context "when there is a page title" do
      before do
        allow(dummy).to receive(:content_for) { title }
      end

      it "is prefixed to the default page title and joined with a dash" do
        expect(dummy.infer_page_title).to eq "#{title} - GovWifi admin"
      end
    end

    context "when there is no page title" do
      before do
        allow(dummy).to receive(:content_for) { nil }
      end

      it "resorts to the default page title" do
        expect(dummy.infer_page_title).to eq "GovWifi admin"
      end
    end
  end
end
