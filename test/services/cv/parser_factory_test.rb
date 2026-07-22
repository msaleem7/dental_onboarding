require "test_helper"

module Cv
  class ParserFactoryTest < ActiveSupport::TestCase
    def teardown
      ENV.delete("LLM_CV_PARSING_ENABLED")
      ENV.delete("ANTHROPIC_API_KEY")
    end

    test "is disabled when the feature flag is off" do
      ENV["LLM_CV_PARSING_ENABLED"] = "false"
      ENV["ANTHROPIC_API_KEY"] = "test-key"

      assert_not Cv::ParserFactory.llm_enabled?
      assert_equal Cv::HeuristicParser.method(:call), Cv::ParserFactory.build
    end

    test "is disabled when no API key is configured, even if the flag is on" do
      ENV["LLM_CV_PARSING_ENABLED"] = "true"
      ENV.delete("ANTHROPIC_API_KEY")

      assert_not Cv::ParserFactory.llm_enabled?
      assert_equal Cv::HeuristicParser.method(:call), Cv::ParserFactory.build
    end

    test "is enabled when the flag is on and an API key is present" do
      ENV["LLM_CV_PARSING_ENABLED"] = "true"
      ENV["ANTHROPIC_API_KEY"] = "test-key"

      assert Cv::ParserFactory.llm_enabled?
      assert_equal Cv::LlmParser.method(:call), Cv::ParserFactory.build
    end
  end
end
