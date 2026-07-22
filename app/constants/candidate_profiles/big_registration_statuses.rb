module CandidateProfiles
  module BigRegistrationStatuses
    BIG_REGISTERED = :big_registered
    IN_PROGRESS = :in_progress
    UNDER_SUPERVISION = :under_supervision
    NOT_APPLICABLE = :not_applicable

    ENUM_MAPPING = {
      BIG_REGISTERED => 0,
      IN_PROGRESS => 1,
      UNDER_SUPERVISION => 2,
      NOT_APPLICABLE => 3
    }.freeze
  end
end
