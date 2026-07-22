module Onboarding
  # Shared base for every step of the candidate onboarding flow. Anything a
  # candidate has to pass through to reach these screens lives here, so the
  # individual step controllers stay focused on their own action.
  class BaseController < ApplicationController
    before_action :require_candidate!

    private

    def require_candidate!
      redirect_to root_path unless Current.user.candidate?
    end

    # Memoized so every onboarding step works against the signed-in
    # candidate's own profile without repeating the lookup.
    def candidate_profile
      @candidate_profile ||= Current.user.candidate_profile
    end
  end
end
