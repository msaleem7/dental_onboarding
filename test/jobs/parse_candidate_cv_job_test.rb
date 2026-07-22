require "test_helper"

class ParseCandidateCvJobTest < ActiveJob::TestCase
  def build_document
    profile = User.create!(email_address: "cvjob#{SecureRandom.hex(4)}@example.com", password: "password123").candidate_profile
    document = profile.candidate_documents.new(
      original_filename: "cv.pdf", content_type: "application/pdf", byte_size: 14
    )
    document.file.attach(io: StringIO.new("fake pdf bytes"), filename: "cv.pdf", content_type: "application/pdf")
    document.save!
    document
  end

  test "marks the document completed and prefills the profile on success" do
    document = build_document

    Cv::TextExtractor.stub(:call, "jane.doe@example.com") do
      ParseCandidateCvJob.perform_now(document.id)
    end

    document.reload
    assert document.completed?
    assert_equal "jane.doe@example.com", document.parsed_data["email"]
    assert_equal "jane.doe@example.com", document.candidate_profile.email
  end

  test "marks the document failed when text extraction fails" do
    document = build_document

    Cv::TextExtractor.stub(:call, ->(_doc) { raise Cv::TextExtractor::ExtractionError, "no text" }) do
      ParseCandidateCvJob.perform_now(document.id)
    end

    document.reload
    assert document.failed?
    assert_equal "no text", document.error_message
  end

  test "marks the document failed instead of raising on unexpected errors" do
    document = build_document

    Cv::TextExtractor.stub(:call, ->(_doc) { raise "boom" }) do
      ParseCandidateCvJob.perform_now(document.id)
    end

    document.reload
    assert document.failed?
  end
end
