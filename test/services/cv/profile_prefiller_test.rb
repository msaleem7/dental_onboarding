require "test_helper"

module Cv
  class ProfilePrefillerTest < ActiveSupport::TestCase
    def new_profile(email: "prefill#{SecureRandom.hex(4)}@example.com")
      User.create!(email_address: email, password: "password123").candidate_profile
    end

    test "fills blank scalar fields but never overwrites data the candidate already entered" do
      profile = new_profile
      profile.update!(first_name: "Existing")
      result = Cv::ExtractionResult.blank
      result.first_name = "From CV"
      result.last_name = "Doe"

      Cv::ProfilePrefiller.call(profile, result)

      assert_equal "Existing", profile.first_name
      assert_equal "Doe", profile.last_name
      assert_includes profile.extracted_fields, "last_name"
      assert_not_includes profile.extracted_fields, "first_name"
    end

    test "skips education entries the parser could not title" do
      profile = new_profile
      result = Cv::ExtractionResult.blank
      result.educations = [ { study: nil, institution: "Some University" }, { study: "Dentistry", institution: nil } ]

      Cv::ProfilePrefiller.call(profile, result)

      assert_equal 1, profile.educations.count
      assert_equal "Dentistry", profile.educations.first.study
      assert profile.educations.first.needs_review?
      assert profile.educations.first.source_cv?
    end

    test "skips work experiences missing a job title or company name" do
      profile = new_profile
      result = Cv::ExtractionResult.blank
      result.work_experiences = [
        { job_title: "Dentist", company_name: nil },
        { job_title: nil, company_name: "Clinic" },
        { job_title: "Dentist", company_name: "Clinic" }
      ]

      Cv::ProfilePrefiller.call(profile, result)

      assert_equal 1, profile.work_experiences.count
      assert_equal "Dentist", profile.work_experiences.first.job_title
    end

    test "re-uploading refreshes CV data without duplicating rows or touching manual edits" do
      profile = new_profile

      first_cv = Cv::ExtractionResult.blank
      first_cv.city = "Amsterdam"
      first_cv.work_experiences = [ { job_title: "Dentist", company_name: "Old Clinic" } ]
      Cv::ProfilePrefiller.call(profile, first_cv)

      # The candidate corrects a field the CV never provided.
      profile.update!(first_name: "Hand Typed")

      second_cv = Cv::ExtractionResult.blank
      second_cv.first_name = "Should Not Win"
      second_cv.city = "Rotterdam"
      second_cv.work_experiences = [ { job_title: "Senior Dentist", company_name: "New Clinic" } ]
      Cv::ProfilePrefiller.call(profile, second_cv)
      profile.reload

      assert_equal "Hand Typed", profile.first_name, "manual edits must survive a re-upload"
      assert_equal "Rotterdam", profile.city, "a CV-sourced field should refresh from the new CV"
      assert_equal 1, profile.work_experiences.count, "old CV rows should be replaced, not duplicated"
      assert_equal "Senior Dentist", profile.work_experiences.first.job_title
    end

    test "matches languages and skills case-insensitively, and adds free-text skill suggestions" do
      profile = new_profile
      language = Language.create!(name: "Dutch")
      skill = Skill.create!(name: "Endodontics", function_group: :dentist)
      result = Cv::ExtractionResult.blank
      result.languages = [ { name: "dutch", level: "native" } ]
      result.skills = [ "endodontics", "SomeMadeUpSkill" ]

      Cv::ProfilePrefiller.call(profile, result)

      assert_equal [ language ], profile.candidate_languages.map(&:language)
      matched = profile.candidate_skills.find { |cs| cs.skill_id == skill.id }
      suggestion = profile.candidate_skills.find { |cs| cs.skill_id.nil? }
      assert matched.present?
      assert_equal "SomeMadeUpSkill", suggestion.skill_name_suggestion
    end
  end
end
