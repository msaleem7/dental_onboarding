module Onboarding
  class ProfilesController < BaseController
    helper_method :profile

    def edit
    end

    def update
      result = CandidateProfiles::CompletionService.call(profile: profile, params: update_params)

      if result.success?
        redirect_to edit_onboarding_profile_path, notice: "Your profile is complete. Thank you!"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    # Memoized so edit and update both work against the same profile without
    # a before_action needing to set an instance variable up front.
    def profile
      @profile ||= Current.user.candidate_profile
    end

    def update_params
      params.expect(
        candidate_profile: [
          :first_name, :last_name, :email, :phone_number, :city, :country,
          :job_function, :max_travel_time_minutes, :search_status, :reason_for_looking,
          :desired_gross_salary, :desired_percentage, :average_daily_revenue,
          :big_registration_status, :big_number, :years_of_experience,
          :available_from, :notice_period, :motivation_for_employer, :skill_suggestions_text,
          preferred_regions: [], transport_types: [], employment_types: [], available_working_days: [], skill_ids: [],
          educations_attributes: [ [ :id, :institution, :study, :city_country, :level, :start_date, :end_date, :_destroy ] ],
          work_experiences_attributes: [ [ :id, :job_title, :company_name, :responsibilities, :start_date, :end_date, :current_job, :_destroy ] ],
          candidate_languages_attributes: [ [ :id, :language_id, :level, :_destroy ] ]
        ]
      )
    end
  end
end
