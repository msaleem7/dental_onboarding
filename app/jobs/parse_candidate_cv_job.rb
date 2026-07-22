class ParseCandidateCvJob < ApplicationJob
  queue_as :default

  # Never leaves parsing_status stuck at "processing": any failure here is
  # recorded on the document as "failed" so the candidate can be routed to
  # manual entry (per PRD) instead of the job endlessly retrying.
  def perform(candidate_document_id)
    document = CandidateDocument.find(candidate_document_id)
    document.update!(parsing_status: :processing)

    text = Cv::TextExtractor.call(document)
    result = Cv::ParserFactory.build.call(text)

    document.update!(
      parsed_data: result.to_h.deep_stringify_keys,
      parsing_status: :completed,
      parsed_at: Time.current,
      error_message: nil
    )
    Cv::ProfilePrefiller.call(document.candidate_profile, result)
  rescue Cv::TextExtractor::ExtractionError => e
    document&.update!(parsing_status: :failed, error_message: e.message)
  rescue StandardError => e
    Rails.logger.error("[ParseCandidateCvJob] CandidateDocument##{candidate_document_id} failed: #{e.class}: #{e.message}")
    document&.update!(parsing_status: :failed, error_message: "Something went wrong while reading this CV.")
  end
end
