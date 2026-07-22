class HomeController < ApplicationController
  allow_unauthenticated_access only: %i[index]

  def index
    return unless authenticated?

    if Current.user.recruiter?
      redirect_to candidates_path
    elsif Current.user.candidate_profile.candidate_documents.none?
      redirect_to new_onboarding_cv_upload_path
    else
      redirect_to edit_onboarding_profile_path
    end
  end
end
