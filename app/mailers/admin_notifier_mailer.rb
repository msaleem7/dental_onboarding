class AdminNotifierMailer < ApplicationMailer
  def onboarding_completed(candidate_profile)
    @profile = candidate_profile
    recipients = User.recruiter.pluck(:email_address)
    return if recipients.empty?

    mail(to: recipients, subject: "New candidate profile completed: #{@profile.full_name}")
  end
end
