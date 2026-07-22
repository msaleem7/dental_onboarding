module ApplicationHelper
  # A small red asterisk that flags a required field. Rendered next to a label so
  # candidates can see at a glance which fields they must fill in before the
  # profile can be submitted.
  def required_marker
    tag.abbr("*", class: "required-marker", title: "Required", aria: { label: "required" })
  end
end
