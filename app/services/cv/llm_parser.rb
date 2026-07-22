module Cv
  # LLM-backed CV parser. Wraps a generic Llm::Client (Anthropic by default,
  # but the interface has no vendor-specific assumptions) and converts its
  # structured JSON response into a Cv::ExtractionResult.
  #
  # On ANY failure (LLM disabled/unconfigured, network error, malformed
  # response, unexpected schema) this falls back to Cv::HeuristicParser so
  # the candidate is never blocked by an LLM outage — see Cv::ParserFactory
  # for how the two parsers are selected.
  class LlmParser
    SCHEMA = {
      type: "object",
      properties: {
        first_name: { type: "string", description: "Candidate's given name" },
        last_name: { type: "string", description: "Candidate's family name" },
        email: { type: "string", description: "Email address" },
        phone_number: { type: "string", description: "Phone number as written in the CV" },
        city: { type: "string", description: "City of residence" },
        country: { type: "string", description: "Country of residence" },
        job_function: {
          type: "string",
          enum: CandidateProfile.job_functions.keys,
          description: "Best-matching job function, only if clearly implied by the CV"
        },
        years_of_experience: { type: "integer", description: "Total years of relevant work experience" },
        big_number: { type: "string", description: "Dutch BIG registration number, if mentioned" },
        professional_summary: { type: "string", description: "Short profile/summary section text, verbatim" },
        languages: {
          type: "array",
          items: {
            type: "object",
            properties: {
              name: { type: "string", enum: Language.pluck(:name), description: "Canonical language name from the allowed list" },
              level: { type: "string", enum: %w[native fluent C2 C1 B2 B1 A2 A1] }
            },
            required: [ "name" ]
          }
        },
        educations: {
          type: "array",
          items: {
            type: "object",
            properties: {
              institution: { type: "string" },
              study: { type: "string" },
              city_country: { type: "string" },
              level: { type: "string" },
              start_date: { type: "string", description: "YYYY-MM-DD, or YYYY-01-01 if only a year is known" },
              end_date: { type: "string", description: "YYYY-MM-DD, or YYYY-01-01 if only a year is known" }
            },
            required: [ "study" ]
          }
        },
        work_experiences: {
          type: "array",
          items: {
            type: "object",
            properties: {
              job_title: { type: "string" },
              company_name: { type: "string" },
              responsibilities: { type: "string" },
              start_date: { type: "string", description: "YYYY-MM-DD, or YYYY-01-01 if only a year is known" },
              end_date: { type: "string", description: "YYYY-MM-DD, omit if current_job is true" },
              current_job: { type: "boolean" }
            },
            required: [ "job_title" ]
          }
        },
        skills: {
          type: "array",
          items: { type: "string" },
          description: "Free-form skill/competency names mentioned in the CV"
        }
      },
      required: %w[languages educations work_experiences skills]
    }.freeze

    INSTRUCTIONS = <<~TEXT.freeze
      You extract structured candidate data from CVs (resumes) for a dental
      recruitment platform. CVs may be written in Dutch or English.

      Critical rules:
      - Only extract information explicitly present in the CV text.
      - Never invent, guess, or infer a value that is not clearly stated.
      - If a field is not present in the CV, omit it (or use an empty array for list fields).
      - Do not translate names, companies, or institutions.
      - Dates: use YYYY-MM-DD. If only a year or month/year is known, use the first day
        (e.g. "2019" -> "2019-01-01", "03/2019" -> "2019-03-01").
      - job_function: only set this if the CV clearly indicates one of the allowed values;
        leave it out otherwise. Do not force a fit.
      - Call the extract_cv_data tool exactly once with the extracted data.
    TEXT

    def self.call(text, client: Llm::AnthropicClient.new)
      new(text, client: client).call
    end

    def initialize(text, client:)
      @text = text
      @client = client
    end

    def call
      data = client.extract_structured(text: text, schema: SCHEMA, instructions: INSTRUCTIONS)
      build_result(data)
    rescue StandardError => e
      Rails.logger.warn("[Cv::LlmParser] falling back to heuristic parser: #{e.class}: #{e.message}")
      Cv::HeuristicParser.call(text)
    end

    private

    attr_reader :text, :client

    def build_result(data)
      result = Cv::ExtractionResult.blank
      result.first_name = data["first_name"].presence
      result.last_name = data["last_name"].presence
      result.email = data["email"].presence
      result.phone_number = data["phone_number"].presence
      result.city = data["city"].presence
      result.country = data["country"].presence
      result.job_function = valid_job_function(data["job_function"])
      result.years_of_experience = data["years_of_experience"]
      result.big_number = data["big_number"].presence
      result.professional_summary = data["professional_summary"].presence
      result.languages = Array(data["languages"]).filter_map { |l| build_language(l) }
      result.educations = Array(data["educations"]).filter_map { |e| build_education(e) }
      result.work_experiences = Array(data["work_experiences"]).filter_map { |w| build_work_experience(w) }
      result.skills = Array(data["skills"]).map(&:to_s).reject(&:blank?).uniq
      result
    end

    def valid_job_function(value)
      value if CandidateProfile.job_functions.key?(value)
    end

    def build_language(entry)
      return nil if entry["name"].blank?
      { name: entry["name"], level: entry["level"].presence }
    end

    def build_education(entry)
      return nil if entry["study"].blank? && entry["institution"].blank?
      {
        institution: entry["institution"].presence,
        study: entry["study"].presence,
        city_country: entry["city_country"].presence,
        level: entry["level"].presence,
        start_date: parse_date(entry["start_date"]),
        end_date: parse_date(entry["end_date"])
      }
    end

    def build_work_experience(entry)
      return nil if entry["job_title"].blank? && entry["company_name"].blank?
      {
        job_title: entry["job_title"].presence,
        company_name: entry["company_name"].presence,
        responsibilities: entry["responsibilities"].presence,
        start_date: parse_date(entry["start_date"]),
        end_date: entry["current_job"] ? nil : parse_date(entry["end_date"]),
        current_job: ActiveModel::Type::Boolean.new.cast(entry["current_job"]) || false
      }
    end

    def parse_date(value)
      return nil if value.blank?
      Date.iso8601(value)
    rescue ArgumentError
      nil
    end
  end
end
