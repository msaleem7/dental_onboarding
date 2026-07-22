class Skill < ApplicationRecord
  enum :function_group, Skills::FunctionGroups::ENUM_MAPPING, prefix: true

  has_many :candidate_skills, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :function_group }

  def self.for_group(group)
    Skills::LookupService.for_group(group)
  end
end
