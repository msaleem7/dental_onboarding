module CandidateProfiles
  # Free-text skill names the candidate typed that don't match an existing Skill.
  # Stored as CandidateSkill rows with skill_id: nil, for recruiter review.
  module SkillSuggestionsService
    def self.assign(profile, text)
      profile.skill_suggestions_text_raw = text
      names = text.to_s.split(",").map(&:strip).reject(&:blank?)

      existing_free_text = profile.candidate_skills.select { |cs| cs.skill_id.nil? }
      existing_free_text.each do |cs|
        profile.candidate_skills.destroy(cs) unless names.include?(cs.skill_name_suggestion)
      end

      names.each do |name|
        next if profile.candidate_skills.any? { |cs| cs.skill_id.nil? && cs.skill_name_suggestion == name }
        profile.candidate_skills.build(skill_name_suggestion: name, source: CandidateSkills::Sources::MANUAL)
      end
    end

    def self.text_for(profile)
      profile.skill_suggestions_text_raw ||
        profile.candidate_skills.select { |cs| cs.skill_id.nil? }.map(&:skill_name_suggestion).join(", ")
    end
  end
end
