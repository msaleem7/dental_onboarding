module CandidateDocuments
  class UploadService
    # Small, immutable value object so the controller can ask "did this work"
    # without reaching into document.errors itself. Success is derived from
    # the document's own persisted state rather than a flag someone hands us,
    # so the Result can never disagree with the record it is wrapping.
    class Result
      attr_reader :document

      def initialize(document)
        @document = document
      end

      def success?
        document.persisted?
      end
    end

    def self.call(candidate_profile:, document_params:, consent_given:)
      new(candidate_profile, document_params, consent_given).call
    end

    def initialize(candidate_profile, document_params, consent_given)
      @candidate_profile = candidate_profile
      @document_params = document_params
      @consent_given = consent_given
    end

    def call
      document = @candidate_profile.candidate_documents.build(@document_params)
      populate_file_metadata(document)

      if @consent_given.blank?
        document.errors.add(:base, "You must consent to processing your CV before continuing")
        return Result.new(document)
      end

      if document.save
        @candidate_profile.update!(consent_given_at: Time.current)
        ParseCandidateCvJob.perform_later(document.id)
      end

      Result.new(document)
    end

    private

    def populate_file_metadata(document)
      return unless document.file.attached?
      document.original_filename = document.file.filename.to_s
      document.content_type = document.file.content_type
      document.byte_size = document.file.byte_size
    end
  end
end
