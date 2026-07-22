module CandidateDocuments
  module AllowedFileTypes
    ALLOWED_CONTENT_TYPES = %w[
      application/pdf
      application/msword
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
    ].freeze

    ALLOWED_EXTENSIONS = %w[.pdf .doc .docx].freeze
  end
end
