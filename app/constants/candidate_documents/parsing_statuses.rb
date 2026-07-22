module CandidateDocuments
  module ParsingStatuses
    PENDING = :pending
    PROCESSING = :processing
    COMPLETED = :completed
    FAILED = :failed

    ENUM_MAPPING = {
      PENDING => 0,
      PROCESSING => 1,
      COMPLETED => 2,
      FAILED => 3
    }.freeze
  end
end
