module Cv
  # Writes a Cv::ExtractionResult into a CandidateProfile and its associations.
  # Never overwrites a field the candidate already filled in, and tracks which
  # fields came from the CV via extracted_fields so the review step can show
  # "extracted from CV" badges (per PRD - the candidate must be able to see
  # and correct anything the parser found).
  class ProfilePrefiller
    SCALAR_FIELDS = %i[
      first_name last_name email phone_number city country
      job_function years_of_experience big_number professional_summary
    ].freeze

    def self.call(candidate_profile, extraction_result)
      new(candidate_profile, extraction_result).call
    end

    def initialize(candidate_profile, extraction_result)
      @profile = candidate_profile
      @result = extraction_result
    end

    def call
      extracted = []

      SCALAR_FIELDS.each do |field|
        value = result.public_send(field)
        next if value.blank?
        next unless fillable?(field)
        profile.public_send("#{field}=", value)
        extracted << field.to_s
      end

      extracted << "languages" if build_languages
      extracted << "educations" if build_educations
      extracted << "work_experiences" if build_work_experiences
      extracted << "skills" if build_skills

      profile.extracted_fields = (profile.extracted_fields + extracted).uniq
      profile.save!(validate: false)
      profile
    end

    private

    attr_reader :profile, :result

    # A scalar is safe to (re)fill when it is still empty, or when the value it
    # already holds came from a previous CV parse. That lets an updated CV
    # refresh what an earlier CV filled, while a value the candidate typed in
    # themselves is always left untouched.
    def fillable?(field)
      profile.public_send(field).blank? || previously_from_cv.include?(field.to_s)
    end

    # Snapshot of the fields that were marked as coming from the CV before this
    # run, so a re-upload knows which values it is allowed to overwrite.
    def previously_from_cv
      @previously_from_cv ||= profile.extracted_fields.dup
    end

    # Clears out rows an earlier CV parse created for this association so an
    # updated CV can rebuild them fresh, without duplicating entries and without
    # disturbing anything the candidate added by hand (source: manual).
    def replace_cv_records(association)
      return unless profile.persisted?
      association.where(source: :cv).destroy_all
    end

    def build_languages
      return false if result.languages.blank?
      replace_cv_records(profile.candidate_languages)

      any_built = false
      result.languages.each do |entry|
        language = Language.find_by("lower(name) = ?", entry[:name].to_s.downcase)
        next unless language
        next if profile.candidate_languages.exists?(language_id: language.id)
        profile.candidate_languages.build(language: language, level: entry[:level], source: :cv)
        any_built = true
      end
      any_built
    end

    def build_educations
      return false if result.educations.blank?
      replace_cv_records(profile.educations)

      any_built = false
      result.educations.each do |entry|
        next if entry[:study].blank? # Education#study is required; skip entries the parser couldn't title

        profile.educations.build(
          study: entry[:study],
          institution: entry[:institution],
          city_country: entry[:city_country],
          start_date: entry[:start_date],
          end_date: entry[:end_date],
          source: :cv,
          needs_review: true
        )
        any_built = true
      end
      any_built
    end

    def build_work_experiences
      return false if result.work_experiences.blank?
      replace_cv_records(profile.work_experiences)

      any_built = false
      result.work_experiences.each do |entry|
        next if entry[:job_title].blank? || entry[:company_name].blank? # both required by WorkExperience

        profile.work_experiences.build(
          job_title: entry[:job_title],
          company_name: entry[:company_name],
          responsibilities: entry[:responsibilities],
          start_date: entry[:start_date],
          end_date: entry[:end_date],
          current_job: entry[:current_job] || false,
          source: :cv,
          needs_review: true
        )
        any_built = true
      end
      any_built
    end

    def build_skills
      return false if result.skills.blank?
      replace_cv_records(profile.candidate_skills)

      any_built = false
      result.skills.each do |name|
        skill = Skill.find_by("lower(name) = ?", name.to_s.downcase)
        if skill
          next if profile.candidate_skills.exists?(skill_id: skill.id)
          profile.candidate_skills.build(skill: skill, source: :cv)
        else
          next if profile.candidate_skills.exists?(skill_name_suggestion: name)
          profile.candidate_skills.build(skill_name_suggestion: name, source: :cv)
        end
        any_built = true
      end
      any_built
    end
  end
end
