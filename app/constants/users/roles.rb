module Users
  module Roles
    CANDIDATE = :candidate
    RECRUITER = :recruiter

    ENUM_MAPPING = {
      CANDIDATE => 0,
      RECRUITER => 1
    }.freeze
  end
end
