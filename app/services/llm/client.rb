module Llm
  # Generic interface for "extract structured JSON from a document" so callers
  # (Cv::LlmParser) never depend on a specific LLM vendor. Swap in a different
  # provider by implementing #extract_structured and updating Cv::ParserFactory.
  class Client
    class Error < StandardError; end

    # Returns a Hash parsed from the model's structured response.
    # Raises Llm::Client::Error on any provider failure.
    def extract_structured(text:, schema:, instructions:)
      raise NotImplementedError
    end
  end
end
