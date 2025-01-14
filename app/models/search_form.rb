class SearchForm
  include ActiveModel::Model

  attr_writer :search_term

  validates :search_term, presence: true

  def search_term
    @search_term&.strip
  end
end
