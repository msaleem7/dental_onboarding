class CandidateLanguage < ApplicationRecord
  belongs_to :candidate_profile
  belongs_to :language

  enum :source, CandidateLanguages::Sources::ENUM_MAPPING, prefix: true

  validates :language_id, uniqueness: { scope: :candidate_profile_id }
  validates :level, inclusion: { in: CandidateLanguages::Levels::LEVELS }, allow_blank: true
end
