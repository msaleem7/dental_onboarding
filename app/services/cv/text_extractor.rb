require "pdf/reader"
require "docx"
require "open3"
require "tempfile"

module Cv
  # Extracts plain text from an uploaded CV so it can be handed to a parser.
  # Raises Cv::TextExtractor::ExtractionError when text can't be recovered —
  # callers should treat that as "parsing failed, let the candidate continue manually".
  class TextExtractor
    class ExtractionError < StandardError; end

    def self.call(candidate_document)
      new(candidate_document).call
    end

    def initialize(candidate_document)
      @candidate_document = candidate_document
    end

    def call
      candidate_document.file.blob.open do |file|
        case candidate_document.extension
        when ".pdf" then extract_pdf(file.path)
        when ".docx" then extract_docx(file.path)
        when ".doc" then extract_doc(file.path)
        else
          raise ExtractionError, "Unsupported file extension: #{candidate_document.extension}"
        end
      end
    end

    private

    attr_reader :candidate_document

    def extract_pdf(path)
      reader = PDF::Reader.new(path)
      text = reader.pages.map(&:text).join("\n")
      raise ExtractionError, "PDF contained no extractable text" if text.strip.empty?
      text
    rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError => e
      raise ExtractionError, "Could not read PDF: #{e.message}"
    end

    def extract_docx(path)
      doc = Docx::Document.open(path)
      text = doc.paragraphs.map(&:text).join("\n")
      raise ExtractionError, "DOCX contained no extractable text" if text.strip.empty?
      text
    rescue Zip::Error => e
      raise ExtractionError, "Could not read DOCX: #{e.message}"
    end

    # Legacy binary .doc has no reliable pure-Ruby parser. We best-effort shell
    # out to macOS's `textutil` when available; otherwise we raise so the
    # candidate is routed to manual entry, per the PRD's required fallback.
    def extract_doc(path)
      raise ExtractionError, "No .doc text extraction tool available" unless textutil_available?

      Tempfile.create([ "cv", ".txt" ]) do |out|
        stdout, stderr, status = Open3.capture3("textutil", "-convert", "txt", "-output", out.path, path)
        raise ExtractionError, "textutil failed: #{stderr}" unless status.success?
        text = File.read(out.path)
        raise ExtractionError, "DOC contained no extractable text" if text.strip.empty?
        text
      end
    end

    def textutil_available?
      system("which textutil > /dev/null 2>&1")
    end
  end
end
