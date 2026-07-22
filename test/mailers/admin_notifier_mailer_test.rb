require "test_helper"

class AdminNotifierMailerTest < ActionMailer::TestCase
  test "notifies all recruiters when a profile completes onboarding" do
    recruiter = User.create!(email_address: "recruiter-a#{SecureRandom.hex(4)}@example.com", password: "password123", role: :recruiter)
    profile = User.create!(email_address: "candidate-mail#{SecureRandom.hex(4)}@example.com", password: "password123").candidate_profile
    profile.update!(first_name: "Jane", last_name: "Doe")

    email = AdminNotifierMailer.onboarding_completed(profile)

    assert_includes email.to, recruiter.email_address
    assert_match "Jane Doe", email.subject
  end

  test "addresses no mail when there are no recruiters" do
    profile = User.create!(email_address: "candidate-mail2#{SecureRandom.hex(4)}@example.com", password: "password123").candidate_profile

    message = AdminNotifierMailer.onboarding_completed(profile).message

    assert_nil message.to
  end
end
