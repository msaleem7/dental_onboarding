require "test_helper"

module Onboarding
  class CvUploadsControllerTest < ActionDispatch::IntegrationTest
    def candidate
      @candidate ||= User.create!(email_address: "cvupload#{SecureRandom.hex(4)}@example.com", password: "password123")
    end

    test "lets a candidate return to upload an updated CV after a first upload" do
      sign_in_as(candidate)
      post onboarding_cv_upload_path, params: {
        candidate_document: { file: fixture_file_upload("cv_sample.pdf", "application/pdf") },
        consent: "1"
      }

      get new_onboarding_cv_upload_path
      assert_response :success
      assert_select "input[type=file]"
    end

    test "requires consent before accepting an upload" do
      sign_in_as(candidate)

      assert_no_enqueued_jobs do
        post onboarding_cv_upload_path, params: {
          candidate_document: { file: fixture_file_upload("cv_sample.pdf", "application/pdf") }
        }
      end

      assert_response :unprocessable_entity
    end

    test "accepts a valid CV upload, enqueues parsing, and redirects to the status page" do
      sign_in_as(candidate)

      assert_enqueued_with(job: ParseCandidateCvJob) do
        post onboarding_cv_upload_path, params: {
          candidate_document: { file: fixture_file_upload("cv_sample.pdf", "application/pdf") },
          consent: "1"
        }
      end

      assert_redirected_to onboarding_status_path
      candidate.candidate_profile.reload
      assert candidate.candidate_profile.consent_given_at.present?
    end

    test "recruiters cannot access the candidate upload flow" do
      recruiter = User.create!(email_address: "recruiter-cv#{SecureRandom.hex(4)}@example.com", password: "password123", role: :recruiter)
      sign_in_as(recruiter)

      get new_onboarding_cv_upload_path
      assert_redirected_to root_path
    end
  end
end
