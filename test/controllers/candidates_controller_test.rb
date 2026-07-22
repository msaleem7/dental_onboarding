require "test_helper"

class CandidatesControllerTest < ActionDispatch::IntegrationTest
  def recruiter
    @recruiter ||= User.create!(email_address: "recruiter-list#{SecureRandom.hex(4)}@example.com", password: "password123", role: :recruiter)
  end

  def completed_candidate
    profile = User.create!(email_address: "candidate-list#{SecureRandom.hex(4)}@example.com", password: "password123").candidate_profile
    profile.update!(first_name: "Jane", last_name: "Doe", onboarding_completed_at: Time.current)
    document = profile.candidate_documents.new
    document.file.attach(io: File.open(Rails.root.join("test/fixtures/files/cv_sample.pdf")), filename: "cv_sample.pdf", content_type: "application/pdf")
    document.original_filename = "cv_sample.pdf"
    document.content_type = "application/pdf"
    document.byte_size = 10
    document.save!(validate: false)
    profile
  end

  test "candidates cannot access the recruiter candidate list" do
    candidate = User.create!(email_address: "not-a-recruiter#{SecureRandom.hex(4)}@example.com", password: "password123")
    sign_in_as(candidate)

    get candidates_path
    assert_redirected_to root_path
  end

  test "recruiters can list and view completed candidate profiles" do
    profile = completed_candidate
    sign_in_as(recruiter)

    get candidates_path
    assert_response :success
    assert_includes response.body, "Jane Doe"

    get candidate_path(profile)
    assert_response :success
  end

  test "recruiters can download a candidate's CV" do
    profile = completed_candidate
    sign_in_as(recruiter)

    get cv_candidate_path(profile)
    assert_response :success
    assert_equal "application/pdf", response.media_type
  end
end
