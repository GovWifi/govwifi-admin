module AccountHealthHelper
  # Red is urgent: notified over 3 months ago, or we can't reach them.
  ACCOUNT_HEALTH_COLOURS = {
    cannot_notify: "red",
    notification_failed: "red",
    overdue: "red",
    follow_up_due: "yellow",
    recently_notified: "green",
  }.freeze

  # [tag colour, label, meaning]
  ACCOUNT_HEALTH_KEY = [
    ["red", "Urgent", "Notified over 3 months ago, or we can't reach them"],
    ["yellow", "Follow up", "Notified 1 to 3 months ago"],
    ["green", "Recently notified", "Notified less than 1 month ago"],
  ].freeze

  def account_health_issue_tag(issue)
    tag.strong(AccountHealthNotification::ISSUE_NAMES.fetch(issue.issue),
               class: "govuk-tag govuk-tag--#{ACCOUNT_HEALTH_COLOURS.fetch(issue.status)}")
  end

  def account_health_no_active_administrators_tag
    tag.strong("No active administrators", class: "govuk-tag govuk-tag--red")
  end
end
