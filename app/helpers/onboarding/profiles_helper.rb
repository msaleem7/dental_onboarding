module Onboarding
  module ProfilesHelper
    def cv_badge_for(profile, field_name)
      return unless profile.field_extracted_from_cv?(field_name)

      tag.span("From CV", class: "badge badge--cv")
    end
  end
end
