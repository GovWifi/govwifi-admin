module OrganisationsHelper
  def sort_link(column, title = nil)
    title ||= column.titleize

    default_sort_direction = column == "name" ? "asc" : "desc"
    direction = column == sort_column ? flip_sort_direction(sort_direction) : default_sort_direction

    govuk_link_to title, { sort: column, direction: direction }
  end

  def flip_sort_direction(current_direction)
    current_direction == "asc" ? "desc" : "asc"
  end

  def mou_created_at_label(organisation)
    if organisation.latest_mou_created_at.present?
      organisation.latest_mou_created_at.strftime("%e %b %Y")
    else
      "-"
    end
  end
end
