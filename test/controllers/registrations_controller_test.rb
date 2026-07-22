require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "creates a candidate account and starts the onboarding flow" do
    assert_difference "User.count", 1 do
      post registration_path, params: { user: {
        email_address: "new-candidate#{SecureRandom.hex(4)}@example.com",
        password: "password123", password_confirmation: "password123"
      } }
    end

    assert_redirected_to new_onboarding_cv_upload_path
    user = User.last
    assert user.candidate?
    assert user.candidate_profile.present?
  end

  test "re-renders the form with errors on mismatched password confirmation" do
    post registration_path, params: { user: {
      email_address: "mismatch@example.com", password: "password123", password_confirmation: "nope"
    } }

    assert_response :unprocessable_entity
    assert_equal 0, User.where(email_address: "mismatch@example.com").count
  end
end
