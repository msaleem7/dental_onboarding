require "test_helper"

class CandidateLanguageTest < ActiveSupport::TestCase
  test "restricts level to the known proficiency scale" do
    profile = User.create!(email_address: "lang#{SecureRandom.hex(4)}@example.com", password: "password123").candidate_profile
    language = Language.create!(name: "Klingon#{SecureRandom.hex(4)}")
    candidate_language = profile.candidate_languages.build(language: language, level: "expert")

    assert_not candidate_language.valid?
    assert_includes candidate_language.errors[:level], "is not included in the list"
  end

  test "prevents duplicate languages for the same profile" do
    profile = User.create!(email_address: "lang2#{SecureRandom.hex(4)}@example.com", password: "password123").candidate_profile
    language = Language.create!(name: "Dutch#{SecureRandom.hex(4)}")
    profile.candidate_languages.create!(language: language, level: "native")
    duplicate = profile.candidate_languages.build(language: language, level: "fluent")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:language_id], "has already been taken"
  end
end
