class CandidateSkill < ApplicationRecord
  belongs_to :candidate_profile
  belongs_to :skill, optional: true

  enum :source, CandidateSkills::Sources::ENUM_MAPPING, prefix: true

  validate :skill_or_suggestion_present

  private

  def skill_or_suggestion_present
    if skill_id.blank? && skill_name_suggestion.blank?
      errors.add(:base, "must reference a skill or provide a suggested skill name")
    end
  end
end
