require "test_helper"

class WorkExperienceTest < ActiveSupport::TestCase
  test "requires a job title and company name" do
    profile = User.create!(email_address: "wx#{SecureRandom.hex(4)}@example.com", password: "password123").candidate_profile
    experience = profile.work_experiences.build

    assert_not experience.valid?
    assert_includes experience.errors[:job_title], "can't be blank"
    assert_includes experience.errors[:company_name], "can't be blank"
  end
end
