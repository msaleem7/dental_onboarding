module CandidateProfiles
  module SearchStatuses
    ACTIVE = :active
    PASSIVE = :passive
    INACTIVE = :inactive

    ENUM_MAPPING = {
      ACTIVE => 0,
      PASSIVE => 1,
      INACTIVE => 2
    }.freeze
  end
end
