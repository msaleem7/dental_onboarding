module CandidateProfiles
  module JobFunctions
    GENERAL_DENTIST = :general_dentist
    DENTAL_HYGIENIST = :dental_hygienist
    DENTAL_ASSISTANT = :dental_assistant
    PREVENTION_ASSISTANT = :prevention_assistant
    PARO_PREVENTION_ASSISTANT = :paro_prevention_assistant
    ORTHODONTIC_ASSISTANT = :orthodontic_assistant
    FRONT_OFFICE = :front_office
    PRACTICE_MANAGER = :practice_manager
    DENTAL_TECHNICIAN = :dental_technician
    SPECIALIST = :specialist

    ENUM_MAPPING = {
      GENERAL_DENTIST => 0,
      DENTAL_HYGIENIST => 1,
      DENTAL_ASSISTANT => 2,
      PREVENTION_ASSISTANT => 3,
      PARO_PREVENTION_ASSISTANT => 4,
      ORTHODONTIC_ASSISTANT => 5,
      FRONT_OFFICE => 6,
      PRACTICE_MANAGER => 7,
      DENTAL_TECHNICIAN => 8,
      SPECIALIST => 9
    }.freeze
  end
end
