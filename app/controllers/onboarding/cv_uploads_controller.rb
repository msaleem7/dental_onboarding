module Onboarding
  class CvUploadsController < BaseController
    def new
      # Reachable both for a first upload and when a candidate comes back to
      # replace their CV with an updated one, so we surface the current file
      # rather than redirecting away.
      @latest_document = candidate_profile.candidate_documents.order(created_at: :desc).first
    end

    def create
      result = CandidateDocuments::UploadService.call(
        candidate_profile: candidate_profile,
        document_params: create_params,
        consent_given: params[:consent]
      )
      @document = result.document

      if result.success?
        redirect_to onboarding_status_path
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def create_params
      params.expect(candidate_document: [ :file ])
    end
  end
end
