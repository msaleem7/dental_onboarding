module Educations
  module Levels
    MBO = :mbo
    HBO = :hbo
    BACHELOR = :bachelor
    MASTER = :master
    DOCTOR = :doctor
    COURSE = :course

    ENUM_MAPPING = {
      MBO => 0,
      HBO => 1,
      BACHELOR => 2,
      MASTER => 3,
      DOCTOR => 4,
      COURSE => 5
    }.freeze
  end
end
