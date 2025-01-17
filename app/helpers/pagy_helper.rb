module PagyHelper
  include Pagy::Frontend

  def pagy_nav_govuk(pagy)
    return "" if pagy.pages == 1

    link   = pagy_link_proc(pagy, link_extra: "class='govuk-link govuk-pagination__link'")
    p_prev = pagy.prev
    p_next = pagy.next

    html = +%(<nav class="pager__govwifi govuk-body" role="navigation" aria-label="Pagination">)
    html << %(<div class="pager__summary">Showing #{pagy.from}-#{pagy.to} of #{pagy.count} items</div>)
    html << %(<div class="pager__controls">)
    html << %(<nav class="govuk-pagination" role="navigation" aria-label="results">)
    if p_prev
      html << %(<div class="govuk-pagination__prev">)
      html << %(<a class="govuk-link govuk-pagination__link" href="#{pagy_url_for(pagy, p_prev)}" rel="prev">)
      html << %(<svg class="govuk-pagination__icon govuk-pagination__icon--prev" xmlns="http://www.w3.org/2000/svg" height="13" width="15" aria-hidden="true" focusable="false" viewBox="0 0 15 13">)
      html << %(<path d="m6.5938-0.0078125-6.7266 6.7266 6.7441 6.4062 1.377-1.449-4.1856-3.9768h12.896v-2h-12.984l4.2931-4.293-1.414-1.414z"></path>)
      html << %(</svg>)
      html << %(<span class="govuk-pagination__link-title">Previous</span></a>)
      html << %(</div>)
    end
    html << %(<ul class="govuk-pagination__list">)

    pagy.series.each do |item| # series example: [1, :gap, 7, 8, "9", 10, 11, :gap, 36]
      html << case item
              when Integer then %(<li class="govuk-pagination__item">#{link.call(item)}</li>) # page link
              when String then %(<li class="govuk-pagination__item govuk-pagination__item--current"><span class="govuk-link govuk-pagination__link" style="color: #fff;">#{item}</span></li>) # current page
              when :gap then %(<li class="govuk-pagination__item">#{pagy_t('pagy.gap')}</li>) # page gap
              end
    end
    html << %(</ul>)
    if p_next
      html << %(<div class="govuk-pagination__next">)
      html << %(<a class="govuk-link govuk-pagination__link" href="#{pagy_url_for(pagy, p_next)}" rel="next">)
      html << %(<span class="govuk-pagination__link-title">Next</span>)
      html << %(<svg class="govuk-pagination__icon govuk-pagination__icon--next" xmlns="http://www.w3.org/2000/svg" height="13" width="15" aria-hidden="true" focusable="false" viewBox="0 0 15 13">)
      html << %(<path d="m8.107-0.0078125-1.4136 1.414 4.2926 4.293h-12.986v2h12.896l-4.1855 3.9766 1.377 1.4492 6.7441-6.4062-6.7246-6.7266z"></path></svg></a>)
      html << %(</div>)
    end
    html << %(</nav>)
    html << %(</div>)
    html << %(</nav>)
  end
end
