module Cv
  # Dependency-free CV parser: regex + keyword dictionaries only, no network
  # calls. Supports Dutch and English CVs at a basic level. Used as the
  # default parser, and as the automatic fallback if the LLM parser is
  # disabled, unconfigured, or fails.
  class HeuristicParser
    SECTION_HEADERS = {
      summary: /\A(profile|summary|about\s*me|profiel|samenvatting|introductie)\s*:?\z/i,
      education: /\A(education|educational\s*background|opleiding(en)?)\s*:?\z/i,
      experience: /\A(work\s*experience|professional\s*experience|employment\s*history|experience|werkervaring|ervaring)\s*:?\z/i,
      skills: /\A(skills|competenties|vaardigheden|expertise)\s*:?\z/i,
      languages: /\A(languages|talen)\s*:?\z/i,
      # Not parsed on its own, but listed so a "Projects" heading closes the
      # experience or education section above it instead of bleeding into it.
      projects: /\A(projects|projecten)\s*:?\z/i
    }.freeze

    JOB_FUNCTION_KEYWORDS = {
      "general_dentist" => %w[tandarts dentist],
      "specialist" => [ "kaakchirurg", "orthodontist", "specialist", "oral surgeon" ],
      "dental_hygienist" => [ "mondhygiënist", "mondhygienist", "dental hygienist", "hygienist" ],
      "prevention_assistant" => [ "preventieassistent", "prevention assistant" ],
      "paro_prevention_assistant" => [ "paro preventieassistent", "paro-prevention assistant", "parodontologie assistent" ],
      "orthodontic_assistant" => [ "orthodontie assistent", "orthodontic assistant" ],
      "dental_assistant" => [ "tandartsassistent", "assistente", "dental assistant" ],
      "front_office" => [ "receptioniste", "front office", "front-office", "balie" ],
      "practice_manager" => [ "praktijkmanager", "practice manager" ],
      "dental_technician" => [ "tandtechnicus", "dental technician" ]
    }.freeze

    LANGUAGE_KEYWORDS = {
      "Dutch" => %w[dutch nederlands], "English" => %w[english engels],
      "German" => %w[german duits], "French" => %w[french frans],
      "Spanish" => %w[spanish spaans], "Portuguese" => %w[portuguese portugees],
      "Polish" => %w[polish pools], "Turkish" => %w[turkish turks],
      "Arabic" => %w[arabic arabisch], "Italian" => %w[italian italiaans]
    }.freeze

    LEVEL_KEYWORDS = {
      "native" => [ "native", "moedertaal", "moedertaal niveau" ],
      "fluent" => %w[fluent vloeiend],
      "C2" => [ "c2" ], "C1" => [ "c1" ], "B2" => [ "b2" ], "B1" => [ "b1" ],
      "A2" => [ "a2" ], "A1" => [ "a1" ]
    }.freeze

    SKILL_SYNONYMS = {
      "root canal" => "Endodontics", "wortelkanaalbehandeling" => "Endodontics",
      "invisalign" => "Aligners / Invisalign", "aligners" => "Aligners / Invisalign",
      "chairside" => "Chairside assistance", "sterilisatie" => "Sterilization",
      "cad/cam" => "CAD/CAM", "cad cam" => "CAD/CAM"
    }.freeze

    def self.call(text)
      new(text).call
    end

    def initialize(text)
      @text = text.to_s
      @lines = @text.split(/\r?\n/).map(&:strip)
    end

    def call
      result = Cv::ExtractionResult.blank
      result.email = extract_email
      result.phone_number = extract_phone
      first, last = extract_name
      result.first_name = first
      result.last_name = last
      result.city = extract_from_dictionary(CityCountryDictionary::CITIES)
      result.country = extract_from_dictionary(CityCountryDictionary::COUNTRIES)
      result.job_function = extract_job_function
      result.years_of_experience = extract_years_of_experience
      result.big_number = extract_big_number
      result.professional_summary = section_body(:summary)&.first(600)
      result.languages = extract_languages
      result.educations = extract_educations
      result.work_experiences = extract_work_experiences
      result.skills = extract_skills
      result
    end

    private

    attr_reader :text, :lines

    def extract_email
      text[/[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}/i]
    end

    def extract_phone
      candidates = text.scan(/(\+?\d[\d\s().\-]{7,}\d)/)
      candidates = candidates.map { |m| m.is_a?(Array) ? m.first : m }
      candidates.map(&:strip).find { |c| c.gsub(/\D/, "").length.between?(8, 15) }
    end

    def extract_name
      header_lines = lines.first(10)
      candidate = header_lines.find do |line|
        next false if line.blank? || line.include?("@")
        words = line.split(/\s+/)
        words.size.between?(2, 4) && words.all? { |w| w =~ /\A[A-ZÀ-Ý][A-Za-zà-ÿ'.\-]*\z/ }
      end
      return [ nil, nil ] unless candidate
      parts = normalize_name(candidate).split(/\s+/)
      [ parts.first, parts[1..].join(" ") ]
    end

    # Resumes often print the name in all caps ("MUHAMMAD SALEEM"). Convert a
    # fully uppercase name to normal title case so it reads naturally, but leave
    # a name that already has mixed case alone so we never mangle forms like McLeod.
    def normalize_name(line)
      return line unless line == line.upcase
      line.split(/\s+/).map(&:capitalize).join(" ")
    end

    def extract_from_dictionary(dictionary)
      lower = text.downcase
      dictionary.find { |name| lower.include?(name.downcase) }
    end

    def extract_job_function
      lower = text.downcase
      scored = JOB_FUNCTION_KEYWORDS.transform_values { |kws| kws.count { |k| lower.include?(k) } }
      best = scored.max_by { |_, count| count }
      best && best.last.positive? ? best.first : nil
    end

    def extract_years_of_experience
      match = text.match(/(\d{1,2})\+?\s*(jaar|jaren|years?)\s*(of\s*)?(experience|ervaring)?/i)
      match && match[1].to_i
    end

    def extract_big_number
      match = text.match(/BIG[\s\-]?(?:nummer|number|nr|registratie)?\s*[:\-]?\s*(\d{8,11})/i)
      match && match[1]
    end

    def extract_languages
      lower = text.downcase
      LANGUAGE_KEYWORDS.filter_map do |canonical_name, keywords|
        keyword = keywords.find { |k| lower.include?(k) }
        next unless keyword
        idx = lower.index(keyword)
        nearby = lower[idx, 80] || ""
        level_key = LEVEL_KEYWORDS.find { |_, words| words.any? { |w| nearby.include?(w) } }&.first
        { name: canonical_name, level: level_key }
      end
    end

    def extract_skills
      lower = text.downcase
      from_seeds = Skill.pluck(:name).select { |name| lower.include?(name.downcase) }
      from_synonyms = SKILL_SYNONYMS.filter_map { |kw, skill_name| skill_name if lower.include?(kw) }
      (from_seeds + from_synonyms).uniq
    end

    # An education entry usually ends on the line that carries the dates
    # (typically "Institution, City | 2016 - 2020"), so we gather lines until we
    # hit a dated line and treat that group as one entry.
    def extract_educations
      section = section_lines(:education)
      return [] if section.empty?

      entries = []
      buffer = []
      section.each do |line|
        buffer << line
        if line.match?(DATE_RANGE)
          entries << build_education(buffer)
          buffer = []
        end
      end
      entries << build_education(buffer) if buffer.any?
      entries.compact.first(6)
    end

    def build_education(buffer)
      return nil if buffer.blank?
      study = buffer.first
      return nil if study.blank?

      dated_line = buffer.find { |line| line.match?(DATE_RANGE) }
      start_date, end_date = dated_line ? extract_date_range(dated_line) : [ nil, nil ]

      # The institution tends to sit on the dated line (before the dates) or on
      # the line right after the study title. Strip the dates and any trailing
      # "| ..." location so we keep just the school name.
      institution_source = (dated_line && dated_line != study) ? dated_line : buffer[1]
      institution = clean_segment(institution_source&.sub(DATE_RANGE, "")&.split("|")&.first)
      institution = nil if institution == study

      { institution: institution, study: study, city_country: nil, level: nil,
        start_date: start_date, end_date: end_date }
    end

    # Every job is anchored on the line that carries its date range, so we find
    # those anchor lines first and reason about the lines around each one. Bullet
    # points and their wrapped continuation lines always attach to the job above
    # them, so a responsibility can never be mistaken for a job of its own.
    def extract_work_experiences
      section = section_lines(:experience)
      anchors = section.each_index.select { |i| date_anchor?(section[i]) }
      return [] if anchors.empty?

      # When the title sits on the date line, the company is the line directly
      # above it. Reserve those company lines so a job never swallows the company
      # heading that actually belongs to the next job below it.
      company_lines = anchors.filter_map { |a| a - 1 if a.positive? && title_on_anchor(section[a]) }

      anchors.each_with_index.filter_map do |anchor, position|
        previous_anchor = position.zero? ? -1 : anchors[position - 1]
        next_anchor = anchors[position + 1] || section.length
        build_work_experience(section, anchor, previous_anchor, next_anchor, company_lines)
      end.first(10)
    end

    def build_work_experience(section, anchor, previous_anchor, next_anchor, company_lines)
      line = section[anchor]
      start_date, end_date = extract_date_range(line)
      current = line.match?(/present|heden|current|nu/i)
      title = title_on_anchor(line)

      below = ((anchor + 1)...next_anchor).reject { |i| company_lines.include?(i) }.map { |i| section[i] }

      if title.present?
        # Layout: "Company  City \n Job Title  09/2025 - Present \n description \n bullets"
        company = anchor.positive? ? clean_segment(section[anchor - 1]) : nil
        responsibilities = clean_responsibilities(collect_bullets(below))
      else
        # The date line has no title of its own, so read the neighbouring lines.
        details = below.reject { |l| bullet?(l) || responsibilities_label?(l) }
        if details.any?
          # Layout: "09/2025 - Present \n Job Title \n Company \n bullets"
          title = clean_segment(details[0])
          company = clean_segment(details[1])
          responsibilities = clean_responsibilities(collect_bullets(below).presence || details[2..])
        else
          # Layout: "Job Title \n Company \n 09/2025 - Present"
          above = ((previous_anchor + 1)...anchor).map { |i| section[i] }
                    .reject { |l| bullet?(l) || responsibilities_label?(l) }
          title = clean_segment(above.size >= 2 ? above[-2] : above[-1])
          company = above.size >= 2 ? clean_segment(above[-1]) : nil
          responsibilities = clean_responsibilities(collect_bullets(below))
        end
      end

      return nil if title.blank? && company.blank?
      { job_title: title.presence || company, company_name: company.presence,
        responsibilities: responsibilities, start_date: start_date,
        end_date: current ? nil : end_date, current_job: current }
    end

    # A date line only anchors a job when it reads like a heading: either the
    # date stands alone, or the text before it is a short label (a job title)
    # rather than a full sentence that merely happens to mention a year range.
    def date_anchor?(line)
      return false if bullet?(line) || !line.match?(DATE_RANGE)
      remainder = line.sub(DATE_RANGE, "").strip
      remainder.empty? || remainder.split(/\s{2,}/).first.to_s.split.size <= 6
    end

    # The job title carried inline on a date line, e.g. the "Senior Dentist" part
    # of "Senior Dentist    09/2025 - Present". Nil when the line is date-only.
    def title_on_anchor(line)
      clean_segment(line.sub(DATE_RANGE, ""))
    end

    def bullet?(line)
      line.to_s.match?(/\A\s*[●•*‣▪◦-]/)
    end

    def responsibilities_label?(line)
      line.to_s.strip.match?(/\Aresponsibilities:?\z/i)
    end

    # Turns a run of lines into a list of whole bullet points. A line that starts
    # with a bullet glyph opens a new point; any following plain line is treated
    # as the wrapped continuation of that point and folded back into it. Lines
    # before the first bullet (such as a company description) are ignored.
    def collect_bullets(source_lines)
      bullets = []
      source_lines.each do |line|
        if bullet?(line)
          bullets << line.sub(/\A\s*[●•*‣▪◦-]\s*/, "").strip
        elsif bullets.any? && !responsibilities_label?(line)
          bullets[-1] = "#{bullets[-1]} #{line.strip}".strip
        end
      end
      bullets
    end

    # Keeps just the meaningful part of a header line. PDFs separate a company
    # from its location (and a title from its dates) with a run of spaces, so we
    # split on that gap and keep the first chunk.
    def clean_segment(text)
      return nil if text.blank?
      text.split(/\s{2,}/).map(&:strip).reject(&:blank?).first
    end

    def clean_responsibilities(points)
      return nil if points.blank?
      points.filter_map { |point| point.to_s.strip.presence }.join("\n").presence
    end

    DATE_RANGE = /(\d{4}|\d{1,2}\/\d{4})\s*[-–—to]+\s*(\d{4}|\d{1,2}\/\d{4}|present|heden|current|nu)/i

    def extract_date_range(entry)
      match = entry.match(DATE_RANGE)
      return [ nil, nil ] unless match
      [ parse_date_token(match[1]), parse_date_token(match[2]) ]
    end

    def parse_date_token(token)
      return nil if token.blank? || token.match?(/present|heden|current|nu/i)
      if token.match?(/\A\d{4}\z/)
        Date.new(token.to_i, 1, 1)
      elsif token.match?(%r{\A\d{1,2}/\d{4}\z})
        month, year = token.split("/").map(&:to_i)
        Date.new(year, month, 1)
      end
    rescue ArgumentError
      nil
    end

    def section_body(key)
      body_lines = section_lines(key)
      return nil if body_lines.empty?
      body_lines.join("\n").strip.presence
    end

    # Returns the stripped, non-blank lines that sit between a section's heading
    # and the next heading (or the end of the CV). This is the raw material both
    # the education and experience extractors segment into individual entries.
    def section_lines(key)
      pattern = SECTION_HEADERS[key]
      start_index = lines.find_index { |line| line.match?(pattern) }
      return [] unless start_index
      remaining = lines[(start_index + 1)..] || []
      end_offset = remaining.find_index { |line| SECTION_HEADERS.values.any? { |p| line.match?(p) } }
      body_lines = end_offset ? remaining[0...end_offset] : remaining
      body_lines.map(&:strip).reject(&:blank?)
    end
  end

  module CityCountryDictionary
    CITIES = %w[
      Amsterdam Rotterdam Utrecht Eindhoven Groningen Tilburg Almere Breda
      Nijmegen Maastricht Arnhem Haarlem Leiden Zwolle Amersfoort Apeldoorn
      Antwerp Brussels Ghent Dusseldorf Cologne Berlin Hamburg Paris London
    ].freeze

    COUNTRIES = [
      "Netherlands", "Nederland", "Belgium", "België", "Germany", "Duitsland",
      "France", "United Kingdom", "Spain", "Portugal", "Poland", "Turkey", "Italy"
    ].freeze
  end
end
