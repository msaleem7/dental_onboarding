require "anthropic"

module Llm
  # Concrete Llm::Client backed by the Anthropic Ruby SDK. Forces a single
  # tool call so the response is guaranteed-shape JSON instead of free text.
  class AnthropicClient < Client
    DEFAULT_MODEL = "claude-opus-4-7".freeze
    TOOL_NAME = "extract_cv_data".freeze

    def initialize(api_key: ENV["ANTHROPIC_API_KEY"], model: ENV.fetch("LLM_MODEL", DEFAULT_MODEL))
      @client = Anthropic::Client.new(api_key: api_key)
      @model = model
    end

    def extract_structured(text:, schema:, instructions:)
      message = client.messages.create(
        model: model,
        max_tokens: 4096,
        system_: [
          { type: "text", text: instructions, cache_control: { type: "ephemeral" } }
        ],
        tools: [
          { name: TOOL_NAME, description: "Return the candidate data extracted from the CV.", input_schema: schema }
        ],
        tool_choice: { type: "tool", name: TOOL_NAME },
        messages: [
          { role: "user", content: text }
        ]
      )

      tool_use = message.content.find { |block| block.type == :tool_use && block.name == TOOL_NAME }
      raise Error, "Model did not return the expected tool call" unless tool_use

      tool_use.input.deep_stringify_keys
    rescue Anthropic::Errors::APIStatusError => e
      raise Error, "Anthropic API error (#{e.type}): #{e.message}"
    rescue Anthropic::Errors::APIError => e
      raise Error, "Anthropic API error: #{e.message}"
    end

    private

    attr_reader :client, :model
  end
end
