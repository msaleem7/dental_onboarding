class CandidateProfile < ApplicationRecord
  # Virtual attribute backing skill_suggestions_text; retains the raw candidate
  # input across a validation failure so the form can redisplay it verbatim.
  attr_accessor :skill_suggestions_text_raw

  belongs_to :user
  has_many :candidate_documents, dependent: :destroy
  has_many :educations, -> { order(:start_date) }, dependent: :destroy
  has_many :work_experiences, -> { order(:start_date) }, dependent: :destroy
  has_many :candidate_skills, dependent: :destroy
  has_many :skills, through: :candidate_skills
  has_many :candidate_languages, dependent: :destroy
  has_many :languages, through: :candidate_languages

  enum :job_function, CandidateProfiles::JobFunctions::ENUM_MAPPING, prefix: true
  enum :search_status, CandidateProfiles::SearchStatuses::ENUM_MAPPING, prefix: true
  enum :big_registration_status, CandidateProfiles::BigRegistrationStatuses::ENUM_MAPPING

  accepts_nested_attributes_for :educations, allow_destroy: true,
    reject_if: ->(attrs) { attrs["study"].blank? && attrs["institution"].blank? }
  accepts_nested_attributes_for :work_experiences, allow_destroy: true,
    reject_if: ->(attrs) { attrs["job_title"].blank? && attrs["company_name"].blank? }
  accepts_nested_attributes_for :candidate_languages, allow_destroy: true,
    reject_if: ->(attrs) { attrs["language_id"].blank? }

  validates :first_name, :last_name, :city, presence: true, on: :complete
  validates :email, presence: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone_number, presence: true, on: :complete,
    format: { with: /\A[+\d][\d\s().-]{6,}\z/, message: "must be a valid phone number" }, allow_blank: true
  validates :job_function, presence: true, on: :complete
  validates :max_travel_time_minutes, presence: true, numericality: { greater_than_or_equal_to: 0 }, on: :complete
  validates :years_of_experience, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :desired_percentage, numericality: { in: 0..100 }, allow_nil: true
  validates :desired_gross_salary, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :average_daily_revenue, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :available_from, presence: true, on: :complete

  validate :preferred_regions_present, on: :complete
  validate :employment_types_present, on: :complete
  validate :available_working_days_present, on: :complete
  validate :big_number_present_if_registered
  validate :at_least_one_language, on: :complete

  def full_name
    [ first_name, last_name ].compact_blank.join(" ")
  end

  def show_big_registration?
    CandidateProfiles::FieldVisibilityService.show_big_registration?(self)
  end

  def show_average_daily_revenue?
    CandidateProfiles::FieldVisibilityService.show_average_daily_revenue?(self)
  end

  def show_desired_salary?
    CandidateProfiles::FieldVisibilityService.show_desired_salary?(self)
  end

  def show_desired_percentage?
    CandidateProfiles::FieldVisibilityService.show_desired_percentage?(self)
  end

  def skill_group_for_job_function
    CandidateProfiles::FieldVisibilityService.skill_group_for_job_function(self)
  end

  def field_extracted_from_cv?(field_name)
    extracted_fields.include?(field_name.to_s)
  end

  def field_missing?(field_name)
    value = public_send(field_name)
    value.respond_to?(:empty?) ? value.empty? : value.nil?
  end

  def skill_suggestions_text=(text)
    CandidateProfiles::SkillSuggestionsService.assign(self, text)
  end

  def skill_suggestions_text
    CandidateProfiles::SkillSuggestionsService.text_for(self)
  end

  private

  def preferred_regions_present
    errors.add(:preferred_regions, "must include at least one region") if preferred_regions.blank?
  end

  def employment_types_present
    errors.add(:employment_types, "must include at least one option") if employment_types.blank?
  end

  def available_working_days_present
    errors.add(:available_working_days, "must include at least one day") if available_working_days.blank?
  end

  def big_number_present_if_registered
    return unless big_registered?
    errors.add(:big_number, "can't be blank when BIG registered") if big_number.blank?
  end

  def at_least_one_language
    errors.add(:base, "at least one language is required") if candidate_languages.reject(&:marked_for_destruction?).empty?
  end
end
