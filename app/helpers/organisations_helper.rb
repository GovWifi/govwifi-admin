module OrganisationsHelper
  def sort_link(column, title = nil)
    title ||= column.titleize
    default_sort_direction = column == "name" ? "asc" : "desc"
    is_active_sort_column = column == sort_column
    direction = is_active_sort_column ? flip_sort_direction(sort_direction) : default_sort_direction
    link_to title, { sort: column, direction: }
  end

  def flip_sort_direction(direction)
    direction == "asc" ? "desc" : "asc"
  end
end
