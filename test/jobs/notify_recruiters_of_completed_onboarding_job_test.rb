require "test_helper"

class NotifyRecruitersOfCompletedOnboardingJobTest < ActiveJob::TestCase
  def teardown
    ENV.delete("ONBOARDING_WEBHOOK_URL")
  end

  def completed_profile
    profile = User.create!(email_address: "notify#{SecureRandom.hex(4)}@example.com", password: "password123").candidate_profile
    profile.update!(
      first_name: "Jane", last_name: "Doe", city: "Amsterdam",
      job_function: "general_dentist", onboarding_completed_at: Time.current
    )
    profile
  end

  test "delivers the recruiter notification email" do
    recruiter = User.create!(email_address: "recruiter-job#{SecureRandom.hex(4)}@example.com", password: "password123", role: :recruiter)
    profile = completed_profile

    perform_enqueued_jobs only: NotifyRecruitersOfCompletedOnboardingJob do
      NotifyRecruitersOfCompletedOnboardingJob.perform_later(profile.id)
    end

    email = ActionMailer::Base.deliveries.last
    assert_includes email.to, recruiter.email_address
  end

  test "does not enqueue the webhook job when no webhook URL is configured" do
    ENV.delete("ONBOARDING_WEBHOOK_URL")
    profile = completed_profile

    assert_no_enqueued_jobs only: CandidateOnboardingWebhookJob do
      NotifyRecruitersOfCompletedOnboardingJob.perform_now(profile.id)
    end
  end

  test "enqueues the webhook job when a webhook URL is configured" do
    ENV["ONBOARDING_WEBHOOK_URL"] = "https://example.com/hooks/onboarding"
    profile = completed_profile

    assert_enqueued_with(job: CandidateOnboardingWebhookJob, args: [ profile.id ]) do
      NotifyRecruitersOfCompletedOnboardingJob.perform_now(profile.id)
    end
  end
end
