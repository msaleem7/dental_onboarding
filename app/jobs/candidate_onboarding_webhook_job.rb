require "net/http"

class CandidateOnboardingWebhookJob < ApplicationJob
  queue_as :default

  EVENT_NAME = "candidate_onboarding_completed".freeze

  def perform(candidate_profile_id)
    url = ENV["ONBOARDING_WEBHOOK_URL"]
    return if url.blank?

    profile = CandidateProfile.find(candidate_profile_id)
    uri = URI.parse(url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"

    request = Net::HTTP::Post.new(uri.request_uri, "Content-Type" => "application/json")
    request.body = payload_for(profile).to_json

    http.request(request)
  rescue StandardError => e
    Rails.logger.error("[CandidateOnboardingWebhookJob] delivery failed for CandidateProfile##{candidate_profile_id}: #{e.class}: #{e.message}")
  end

  private

  def payload_for(profile)
    {
      event: EVENT_NAME,
      candidate_profile_id: profile.id,
      full_name: profile.full_name,
      job_function: profile.job_function,
      city: profile.city,
      completed_at: profile.onboarding_completed_at
    }
  end
end
