class CandidatesController < ApplicationController
  before_action :require_recruiter!
  helper_method :candidate

  def index
    @candidates = Candidates::ListService.call
  end

  def show
  end

  # Streams the CV file through an authenticated, authorized controller action
  # rather than redirecting to a signed Active Storage URL, so the file is
  # never reachable without a recruiter session.
  def cv
    result = Candidates::CvDownloadService.call(candidate)

    if result.success?
      send_data result.document.file.download,
        filename: result.document.original_filename.presence || "cv#{result.document.extension}",
        type: result.document.content_type.presence || "application/octet-stream",
        disposition: "attachment"
    else
      redirect_to candidate_path(candidate), alert: "No CV is available for this candidate."
    end
  end

  private

  # Memoized so show and cv can both reach for the same profile without
  # querying twice, and without a before_action hiding where it comes from.
  def candidate
    @candidate ||= CandidateProfile.find(params[:id])
  end

  def require_recruiter!
    redirect_to root_path, alert: "Not authorized" unless Current.user.recruiter?
  end
end
