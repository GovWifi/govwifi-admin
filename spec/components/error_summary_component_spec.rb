# frozen_string_literal: true

require "rails_helper"

RSpec.describe ErrorSummaryComponent, type: :component do
  it "renders the title and list" do
    render_inline(described_class.new(title: "Error", list: ["Item 1", "Item 2"]))

    expect(page).to have_css(".govuk-error-summary__title", text: "Error")
    expect(page).to have_css("li", text: "Item 1")
    expect(page).to have_css("li", text: "Item 2")
  end

  it "renders optional block content" do
    render_inline(described_class.new(title: "Error", list: [])) do
      "Extra content here"
    end

    expect(page).to have_content("Extra content here")
  end
end
