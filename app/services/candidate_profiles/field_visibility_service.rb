module CandidateProfiles
  module FieldVisibilityService
    def self.show_big_registration?(profile)
      profile.job_function.present? &&
        CandidateProfiles::EligibilityRules::BIG_ELIGIBLE_FUNCTIONS.include?(profile.job_function)
    end

    def self.show_average_daily_revenue?(profile)
      profile.job_function.present? &&
        CandidateProfiles::EligibilityRules::REVENUE_ELIGIBLE_FUNCTIONS.include?(profile.job_function)
    end

    def self.show_desired_salary?(profile)
      profile.employment_types.include?("employed")
    end

    def self.show_desired_percentage?(profile)
      (profile.employment_types & CandidateProfiles::EligibilityRules::PERCENTAGE_BASED_EMPLOYMENT_TYPES).any?
    end

    def self.skill_group_for_job_function(profile)
      CandidateProfiles::JobFunctionSkillGroups::JOB_FUNCTION_TO_SKILL_GROUP[profile.job_function]
    end
  end
end
