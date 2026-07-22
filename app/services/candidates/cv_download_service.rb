module Candidates
  class CvDownloadService
    class Result
      attr_reader :document

      def initialize(document:)
        @document = document
      end

      # A document only counts as downloadable once its file has actually
      # been uploaded to Active Storage, not just because a record exists for it.
      def success?
        document&.file&.attached? || false
      end
    end

    def self.call(candidate_profile)
      document = candidate_profile.candidate_documents.order(created_at: :desc).first
      Result.new(document: document)
    end
  end
end
