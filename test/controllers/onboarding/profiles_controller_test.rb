require "test_helper"

module Onboarding
  class ProfilesControllerTest < ActionDispatch::IntegrationTest
    def candidate
      @candidate ||= User.create!(email_address: "profile#{SecureRandom.hex(4)}@example.com", password: "password123")
    end

    def valid_params(language_id:)
      {
        candidate_profile: {
          first_name: "Jane", last_name: "Doe", city: "Amsterdam",
          phone_number: "+31612345678", job_function: "general_dentist",
          max_travel_time_minutes: 30, preferred_regions: [ "Utrecht" ],
          employment_types: [ "employed" ], available_working_days: [ "monday" ],
          available_from: Date.tomorrow.to_s, big_registration_status: "not_applicable",
          candidate_languages_attributes: { "0" => { language_id: language_id, level: "native" } }
        }
      }
    end

    test "renders the edit form for the signed-in candidate" do
      sign_in_as(candidate)
      get edit_onboarding_profile_path
      assert_response :success
    end

    test "completes onboarding, enqueues recruiter notification, and redirects on valid data" do
      sign_in_as(candidate)
      language = Language.create!(name: "Dutch#{SecureRandom.hex(4)}")

      assert_enqueued_with(job: NotifyRecruitersOfCompletedOnboardingJob, args: [ candidate.candidate_profile.id ]) do
        patch onboarding_profile_path, params: valid_params(language_id: language.id)
      end

      assert_redirected_to edit_onboarding_profile_path
      follow_redirect!
      assert_response :success
      candidate.candidate_profile.reload
      assert candidate.candidate_profile.onboarding_completed_at.present?
    end

    test "re-renders with errors and does not mark onboarding complete when required data is missing" do
      sign_in_as(candidate)

      patch onboarding_profile_path, params: { candidate_profile: { first_name: "Jane" } }

      assert_response :unprocessable_entity
      candidate.candidate_profile.reload
      assert_nil candidate.candidate_profile.onboarding_completed_at
    end
  end
end
