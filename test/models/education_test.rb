require "test_helper"

class EducationTest < ActiveSupport::TestCase
  test "requires a study field" do
    profile = User.create!(email_address: "edu#{SecureRandom.hex(4)}@example.com", password: "password123").candidate_profile
    education = profile.educations.build

    assert_not education.valid?
    assert_includes education.errors[:study], "can't be blank"
  end
end
