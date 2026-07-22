class Education < ApplicationRecord
  belongs_to :candidate_profile

  enum :level, Educations::Levels::ENUM_MAPPING, prefix: true
  enum :source, Educations::Sources::ENUM_MAPPING, prefix: true

  validates :study, presence: true
end
