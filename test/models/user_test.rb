require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "requires a unique, case-insensitive email address" do
    User.create!(email_address: "taken@example.com", password: "password123")
    duplicate = User.new(email_address: "TAKEN@example.com", password: "password123")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email_address], "has already been taken"
  end

  test "rejects invalid email formats" do
    user = User.new(email_address: "not-an-email", password: "password123")

    assert_not user.valid?
    assert_includes user.errors[:email_address], "is invalid"
  end

  test "defaults to the candidate role" do
    user = User.create!(email_address: "default-role@example.com", password: "password123")

    assert user.candidate?
  end

  test "automatically creates a candidate profile for candidates after commit" do
    user = User.create!(email_address: "candidate-profile@example.com", password: "password123", role: :candidate)

    assert user.candidate_profile.present?
  end

  test "does not create a candidate profile for recruiters" do
    user = User.create!(email_address: "recruiter-profile@example.com", password: "password123", role: :recruiter)

    assert_nil user.candidate_profile
  end
end
