class WorkExperience < ApplicationRecord
  belongs_to :candidate_profile

  enum :source, WorkExperiences::Sources::ENUM_MAPPING, prefix: true

  validates :job_title, :company_name, presence: true
end
