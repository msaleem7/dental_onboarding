require "test_helper"

module Cv
  class LlmParserTest < ActiveSupport::TestCase
    class FakeClient
      def initialize(response: nil, error: nil)
        @response = response
        @error = error
      end

      def extract_structured(text:, schema:, instructions:)
        raise @error if @error
        @response
      end
    end

    test "converts a structured response into an ExtractionResult" do
      client = FakeClient.new(response: {
        "first_name" => "Jane", "last_name" => "Doe", "job_function" => "general_dentist",
        "languages" => [ { "name" => "Dutch", "level" => "native" } ],
        "educations" => [ { "study" => "Dentistry", "start_date" => "2015-01-01" } ],
        "work_experiences" => [ { "job_title" => "Dentist", "company_name" => "Clinic", "current_job" => true } ],
        "skills" => [ "Endodontics", "Endodontics", "" ]
      })

      result = Cv::LlmParser.call("cv text", client: client)

      assert_equal "Jane", result.first_name
      assert_equal "general_dentist", result.job_function
      assert_equal [ { name: "Dutch", level: "native" } ], result.languages
      assert_equal "Dentistry", result.educations.first[:study]
      assert_equal Date.new(2015, 1, 1), result.educations.first[:start_date]
      assert result.work_experiences.first[:current_job]
      assert_nil result.work_experiences.first[:end_date]
      assert_equal [ "Endodontics" ], result.skills
    end

    test "ignores a job_function the model invents outside the allowed enum" do
      client = FakeClient.new(response: {
        "job_function" => "astronaut",
        "languages" => [], "educations" => [], "work_experiences" => [], "skills" => []
      })

      result = Cv::LlmParser.call("cv text", client: client)

      assert_nil result.job_function
    end

    test "falls back to the heuristic parser when the client raises" do
      client = FakeClient.new(error: Llm::Client::Error.new("boom"))

      result = Cv::LlmParser.call("jane.doe@example.com", client: client)

      assert_equal "jane.doe@example.com", result.email
    end
  end
end
