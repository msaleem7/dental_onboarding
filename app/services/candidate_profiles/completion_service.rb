module CandidateProfiles
  class CompletionService
    # Success here means one thing in this domain: onboarding actually got
    # marked complete. Rather than trust a boolean passed in from call, the
    # Result reads that straight off the profile it is wrapping.
    class Result
      attr_reader :profile

      def initialize(profile)
        @profile = profile
      end

      def success?
        profile.onboarding_completed_at.present?
      end
    end

    def self.call(profile:, params:)
      new(profile, params).call
    end

    def initialize(profile, params)
      @profile = profile
      @params = params
    end

    def call
      @profile.assign_attributes(@params)
      @profile.onboarding_completed_at ||= Time.current

      if @profile.save(context: :complete)
        NotifyRecruitersOfCompletedOnboardingJob.perform_later(@profile.id)
      else
        @profile.onboarding_completed_at = nil
      end

      Result.new(@profile)
    end
  end
end
