module Candidates
  module ListService
    def self.call
      CandidateProfile.where.not(onboarding_completed_at: nil).order(onboarding_completed_at: :desc)
    end
  end
end
