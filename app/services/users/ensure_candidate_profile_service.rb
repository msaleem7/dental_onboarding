module Users
  module EnsureCandidateProfileService
    def self.call(user)
      return unless user.candidate?
      user.create_candidate_profile! if user.candidate_profile.nil?
    end
  end
end
