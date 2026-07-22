module Skills
  module LookupService
    def self.for_group(group)
      return Skill.none if group.blank?
      Skill.where(function_group: group).order(:name)
    end
  end
end
