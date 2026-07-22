module CandidateProfiles
  # Maps job_function -> Skill#function_group so the right skill list is shown.
  module JobFunctionSkillGroups
    JOB_FUNCTION_TO_SKILL_GROUP = {
      "general_dentist" => "dentist",
      "specialist" => "dentist",
      "dental_hygienist" => "dental_hygienist",
      "dental_assistant" => "dental_assistant",
      "prevention_assistant" => "dental_assistant",
      "paro_prevention_assistant" => "dental_assistant",
      "orthodontic_assistant" => "dental_assistant",
      "front_office" => "front_office",
      "practice_manager" => "practice_manager",
      "dental_technician" => "dental_technician"
    }.freeze
  end
end
