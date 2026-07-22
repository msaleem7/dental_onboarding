require "test_helper"

module Cv
  class HeuristicParserTest < ActiveSupport::TestCase
    test "extracts contact details, job function, city, and skills without inventing data" do
      Skill.create!(name: "Endodontics", function_group: :dentist)

      text = <<~CV
        Jane Doe
        jane.doe@example.com
        +31 6 12345678

        Profile:
        Experienced general dentist based in Amsterdam, Netherlands.

        Work experience:
        2019 - present
        General Dentist
        Bright Smile Clinic
        Root canal treatments and patient care.

        Skills:
        Endodontics, patient communication
      CV

      result = Cv::HeuristicParser.call(text)

      assert_equal "jane.doe@example.com", result.email
      assert_equal "Jane", result.first_name
      assert_equal "Doe", result.last_name
      assert_equal "general_dentist", result.job_function
      assert_equal "Amsterdam", result.city
      assert_equal "Netherlands", result.country
      assert_includes result.skills, "Endodontics"
      assert_nil result.big_number
    end

    test "reads an all-caps name and presents it in normal title case" do
      text = <<~CV
        MUHAMMAD SALEEM
        Senior Full Stack Engineer
        saleem@example.com
      CV

      result = Cv::HeuristicParser.call(text)

      assert_equal "Muhammad", result.first_name
      assert_equal "Saleem", result.last_name
    end

    test "recognizes a plain Experience heading and stops it at a Projects heading" do
      text = <<~CV
        Experience
        Software Engineer
        Acme Corp
        2019 - 2023

        Projects
        Secret Side Project
        Personal
      CV

      result = Cv::HeuristicParser.call(text)

      titles = result.work_experiences.map { |experience| experience[:job_title] }
      assert_includes titles, "Software Engineer", "a plain 'Experience' heading should yield work history"
      leaked = result.work_experiences.any? { |experience| experience.values.join(" ").include?("Secret Side Project") }
      refute leaked, "content under Projects must not bleed into work experience"
    end

    test "keeps each job whole: company, title, responsibilities without splitting bullets into jobs" do
      text = <<~CV
        Work Experience
        Bright Smile Clinic
        Senior Dentist  01/2021 - Present
        ● Performed root canal treatments and complex restorations.
        ● Mentored two junior dentists.
        Old Town Practice
        Associate Dentist  06/2017 - 12/2020
        ● Delivered routine and preventive care.

        Education
        Master of Dentistry
        University of Amsterdam | 2011 - 2016
      CV

      result = Cv::HeuristicParser.call(text)

      assert_equal 2, result.work_experiences.length, "each dated job should be a single entry, not one per bullet"

      first = result.work_experiences.first
      assert_equal "Senior Dentist", first[:job_title]
      assert_equal "Bright Smile Clinic", first[:company_name]
      assert first[:current_job]
      assert_includes first[:responsibilities], "root canal treatments"
      assert_includes first[:responsibilities], "Mentored two junior dentists"

      second = result.work_experiences.second
      assert_equal "Associate Dentist", second[:job_title]
      assert_equal "Old Town Practice", second[:company_name]

      no_bullet_titles = result.work_experiences.none? { |experience| experience[:job_title].to_s.start_with?("●") }
      assert no_bullet_titles, "a bullet line must never become a job title"

      education = result.educations.first
      assert_equal "Master of Dentistry", education[:study]
      assert_equal "University of Amsterdam", education[:institution]
    end

    test "leaves fields blank rather than guessing when nothing matches" do
      result = Cv::HeuristicParser.call("Not a CV at all, just some unrelated text.")

      assert_nil result.email
      assert_nil result.job_function
      assert_equal [], result.skills
      assert_equal [], result.educations
      assert_equal [], result.work_experiences
    end
  end
end
