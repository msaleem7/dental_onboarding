module Cv
  # Common structured output shape that every parser (heuristic or LLM) must
  # produce, so Cv::ProfilePrefiller doesn't need to know which parser ran.
  # Any field left nil/empty means "not found in the CV" — never guessed.
  ExtractionResult = Struct.new(
    :first_name, :last_name, :email, :phone_number, :city, :country,
    :job_function, :years_of_experience, :big_number, :big_registration_status,
    :professional_summary,
    :languages,        # [{ name:, level: }]
    :educations,       # [{ institution:, study:, city_country:, level:, start_date:, end_date: }]
    :work_experiences, # [{ job_title:, company_name:, responsibilities:, start_date:, end_date:, current_job: }]
    :skills,           # ["Endodontics", ...] free-form names, matched to Skill table later
    keyword_init: true
  ) do
    def self.blank
      new(languages: [], educations: [], work_experiences: [], skills: [])
    end

    def present_fields
      to_h.select { |_, v| v.respond_to?(:empty?) ? !v.empty? : !v.nil? }.keys
    end
  end
end
