class NotifyRecruitersOfCompletedOnboardingJob < ApplicationJob
  queue_as :default

  def perform(candidate_profile_id)
    profile = CandidateProfile.find(candidate_profile_id)
    AdminNotifierMailer.onboarding_completed(profile).deliver_now
    CandidateOnboardingWebhookJob.perform_later(profile.id) if ENV["ONBOARDING_WEBHOOK_URL"].present?
  end
end
