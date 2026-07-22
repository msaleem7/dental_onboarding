require "test_helper"

class CandidateProfileTest < ActiveSupport::TestCase
  def new_candidate_profile(email: "candidate#{SecureRandom.hex(4)}@example.com")
    User.create!(email_address: email, password: "password123", role: :candidate).candidate_profile
  end

  test "BIG registration is only relevant for BIG-eligible job functions" do
    profile = new_candidate_profile
    profile.job_function = "general_dentist"
    assert profile.show_big_registration?

    profile.job_function = "front_office"
    assert_not profile.show_big_registration?
  end

  test "average daily revenue is only relevant for revenue-eligible job functions" do
    profile = new_candidate_profile
    profile.job_function = "prevention_assistant"
    assert profile.show_average_daily_revenue?

    profile.job_function = "dental_technician"
    assert_not profile.show_average_daily_revenue?
  end

  test "desired salary is shown for employed candidates, not percentage-based ones" do
    profile = new_candidate_profile
    profile.employment_types = [ "employed" ]

    assert profile.show_desired_salary?
    assert_not profile.show_desired_percentage?
  end

  test "desired percentage is shown for percentage-based employment types" do
    profile = new_candidate_profile
    profile.employment_types = [ "freelance" ]

    assert profile.show_desired_percentage?
    assert_not profile.show_desired_salary?
  end

  test "skill_group_for_job_function maps dentist-adjacent roles to the dentist group" do
    profile = new_candidate_profile
    profile.job_function = "specialist"

    assert_equal "dentist", profile.skill_group_for_job_function
  end

  test "field_extracted_from_cv? reflects the extracted_fields list" do
    profile = new_candidate_profile
    profile.extracted_fields = [ "first_name" ]

    assert profile.field_extracted_from_cv?(:first_name)
    assert_not profile.field_extracted_from_cv?(:last_name)
  end

  test "field_missing? treats blank strings and nils as missing" do
    profile = new_candidate_profile
    profile.first_name = nil
    assert profile.field_missing?(:first_name)

    profile.first_name = "Jane"
    assert_not profile.field_missing?(:first_name)
  end

  test "skill_suggestions_text= builds free-text suggestions and stays in sync on reassignment" do
    profile = new_candidate_profile
    profile.skill_suggestions_text = "Botox, Custom Skill"
    profile.save!(validate: false)

    suggestions = profile.candidate_skills.reload.select { |cs| cs.skill_id.nil? }
    assert_equal [ "Botox", "Custom Skill" ], suggestions.map(&:skill_name_suggestion).sort

    profile.skill_suggestions_text = "Botox"
    profile.save!(validate: false)

    assert_equal [ "Botox" ], profile.candidate_skills.reload.select { |cs| cs.skill_id.nil? }.map(&:skill_name_suggestion)
  end

  test "is invalid in the complete context when required fields are missing" do
    profile = new_candidate_profile

    assert_not profile.save(context: :complete)
    assert_includes profile.errors[:first_name], "can't be blank"
    assert_includes profile.errors[:job_function], "can't be blank"
    assert_includes profile.errors[:preferred_regions], "must include at least one region"
    assert_includes profile.errors[:base], "at least one language is required"
  end

  test "is valid in the complete context once all required data is present" do
    profile = new_candidate_profile
    language = Language.create!(name: "Dutch#{SecureRandom.hex(4)}")

    profile.assign_attributes(
      first_name: "Jane", last_name: "Doe", city: "Amsterdam",
      phone_number: "+31612345678", job_function: "general_dentist",
      max_travel_time_minutes: 30, preferred_regions: [ "Utrecht" ],
      employment_types: [ "employed" ], available_working_days: [ "monday" ],
      available_from: Date.tomorrow, big_registration_status: :not_applicable
    )
    profile.candidate_languages.build(language: language, level: "native")

    assert profile.save(context: :complete), profile.errors.full_messages.to_sentence
  end

  test "requires a BIG number when BIG registered, in any context" do
    profile = new_candidate_profile
    profile.big_registration_status = :big_registered
    profile.big_number = nil

    assert_not profile.valid?
    assert_includes profile.errors[:big_number], "can't be blank when BIG registered"
  end
end
