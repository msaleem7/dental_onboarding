module CandidateProfiles
  # Which job functions / employment types make certain profile fields relevant
  # (BIG registration, average daily revenue, desired percentage vs. salary).
  module EligibilityRules
    BIG_ELIGIBLE_FUNCTIONS = %w[general_dentist dental_hygienist specialist].freeze

    REVENUE_ELIGIBLE_FUNCTIONS = %w[general_dentist dental_hygienist specialist prevention_assistant].freeze

    PERCENTAGE_BASED_EMPLOYMENT_TYPES = %w[self_employed freelance percentage_based].freeze
  end
end
