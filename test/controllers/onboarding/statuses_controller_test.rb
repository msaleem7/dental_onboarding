require "test_helper"

module Onboarding
  class StatusesControllerTest < ActionDispatch::IntegrationTest
    def candidate
      @candidate ||= User.create!(email_address: "status#{SecureRandom.hex(4)}@example.com", password: "password123")
    end

    def build_document(parsing_status:)
      candidate.candidate_profile.candidate_documents.create!(
        parsing_status: parsing_status,
        original_filename: "cv_sample.pdf",
        file: fixture_file_upload("cv_sample.pdf", "application/pdf")
      )
    end

    test "shows the waiting screen while the CV is still being parsed" do
      sign_in_as(candidate)
      build_document(parsing_status: :processing)

      get onboarding_status_path

      assert_response :success
      assert_select ".spinner"
    end

    test "forwards to the review page once parsing has completed" do
      sign_in_as(candidate)
      build_document(parsing_status: :completed)

      get onboarding_status_path

      assert_redirected_to edit_onboarding_profile_path
    end

    test "forwards to the review page with a notice when parsing failed" do
      sign_in_as(candidate)
      build_document(parsing_status: :failed)

      get onboarding_status_path

      assert_redirected_to edit_onboarding_profile_path
      assert flash[:alert].present?
    end

    test "redirects to the upload page when no CV has been uploaded yet" do
      sign_in_as(candidate)

      get onboarding_status_path

      assert_redirected_to new_onboarding_cv_upload_path
    end
  end
end
