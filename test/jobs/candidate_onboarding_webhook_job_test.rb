require "test_helper"

class CandidateOnboardingWebhookJobTest < ActiveJob::TestCase
  def teardown
    ENV.delete("ONBOARDING_WEBHOOK_URL")
  end

  def completed_profile
    profile = User.create!(email_address: "webhook#{SecureRandom.hex(4)}@example.com", password: "password123").candidate_profile
    profile.update!(
      first_name: "Jane", last_name: "Doe", city: "Amsterdam",
      job_function: "general_dentist", onboarding_completed_at: Time.current
    )
    profile
  end

  test "does nothing when no webhook URL is configured" do
    ENV.delete("ONBOARDING_WEBHOOK_URL")
    profile = completed_profile

    assert_nothing_raised do
      CandidateOnboardingWebhookJob.perform_now(profile.id)
    end
  end

  test "posts the profile payload as JSON to the configured URL" do
    ENV["ONBOARDING_WEBHOOK_URL"] = "https://example.com/hooks/onboarding"
    profile = completed_profile

    http_double = Minitest::Mock.new
    http_double.expect(:use_ssl=, nil, [ true ])
    posted_request = nil
    http_double.expect(:request, Net::HTTPOK.new("1.1", "200", "OK")) do |req|
      posted_request = req
      req.is_a?(Net::HTTP::Post)
    end

    Net::HTTP.stub(:new, http_double) do
      CandidateOnboardingWebhookJob.perform_now(profile.id)
    end

    http_double.verify
    body = JSON.parse(posted_request.body)
    assert_equal "candidate_onboarding_completed", body["event"]
    assert_equal "Jane Doe", body["full_name"]
  end
end
