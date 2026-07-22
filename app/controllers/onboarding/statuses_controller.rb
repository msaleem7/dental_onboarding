module Onboarding
  class StatusesController < BaseController
    def show
      @document = candidate_profile.candidate_documents.order(created_at: :desc).first
      return redirect_to new_onboarding_cv_upload_path unless @document

      # The status page is only a waiting screen for the background parse. As
      # soon as parsing settles, send the candidate straight to the review step
      # instead of asking them to click through an extra "all done" page.
      forward_to_review if @document.completed? || @document.failed?
    end

    private

    def forward_to_review
      alert = "We couldn't automatically read your CV, so please fill in your profile below." if @document.failed?
      redirect_to edit_onboarding_profile_path, alert: alert
    end
  end
end
