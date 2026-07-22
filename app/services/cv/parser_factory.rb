module Cv
  # Picks which parser handles a CV. LLM parsing is opt-in: it only runs when
  # explicitly enabled AND an API key is configured. Any other state (flag
  # off, no key, or an LLM failure at call time inside Cv::LlmParser) uses
  # the dependency-free heuristic parser instead.
  module ParserFactory
    def self.build
      llm_enabled? ? Cv::LlmParser.method(:call) : Cv::HeuristicParser.method(:call)
    end

    def self.llm_enabled?
      ActiveModel::Type::Boolean.new.cast(ENV["LLM_CV_PARSING_ENABLED"]) && ENV["ANTHROPIC_API_KEY"].present?
    end
  end
end
