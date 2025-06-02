# frozen_string_literal: true

class ErrorSummaryComponent < ViewComponent::Base
  def initialize(title:, list:)
    super
    @title = title
    @list = list
  end
end
