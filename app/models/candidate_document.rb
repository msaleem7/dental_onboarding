class CandidateDocument < ApplicationRecord
  belongs_to :candidate_profile
  has_one_attached :file

  enum :document_type, CandidateDocuments::DocumentTypes::ENUM_MAPPING
  enum :parsing_status, CandidateDocuments::ParsingStatuses::ENUM_MAPPING

  validate :file_attached
  validate :file_type_allowed
  validate :file_size_within_limit

  def extension
    File.extname(original_filename.to_s).downcase
  end

  private

  def file_attached
    errors.add(:file, "must be attached") unless file.attached?
  end

  def file_type_allowed
    return unless file.attached?
    allowed_types = CandidateDocuments::AllowedFileTypes::ALLOWED_CONTENT_TYPES
    allowed_extensions = CandidateDocuments::AllowedFileTypes::ALLOWED_EXTENSIONS
    unless allowed_types.include?(file.content_type) && allowed_extensions.include?(extension)
      errors.add(:file, "must be a PDF, DOC, or DOCX file")
    end
  end

  def file_size_within_limit
    return unless file.attached?
    max_bytes = CandidateDocuments::UploadLimits.max_size_bytes
    if file.byte_size > max_bytes
      errors.add(:file, "is too large (maximum is #{max_bytes / 1.megabyte} MB)")
    end
  end
end
