class CreateCandidateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :candidate_profiles do |t|
      t.references :user, null: false, foreign_key: true

      # 3.1 Personal details
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone_number
      t.string :city
      t.string :country

      # 3.2 Job preferences
      t.integer :job_function
      t.string :preferred_regions, array: true, default: [], null: false
      t.integer :max_travel_time_minutes
      t.string :transport_types, array: true, default: [], null: false
      t.integer :search_status
      t.text :reason_for_looking

      # 3.3 Employment and compensation
      t.string :employment_types, array: true, default: [], null: false
      t.integer :desired_gross_salary
      t.integer :desired_percentage
      t.decimal :average_daily_revenue, precision: 10, scale: 2
      t.integer :big_registration_status
      t.string :big_number
      t.decimal :years_of_experience, precision: 4, scale: 1

      # 3.7 Availability
      t.string :available_working_days, array: true, default: [], null: false
      t.date :available_from
      t.string :notice_period

      # 3.8 Additional information
      t.text :motivation_for_employer
      t.text :internal_notes
      t.text :professional_summary

      # Onboarding / CV-parsing meta
      t.string :extracted_fields, array: true, default: [], null: false
      t.datetime :consent_given_at
      t.datetime :onboarding_completed_at

      t.timestamps
    end

    add_index :candidate_profiles, :email
    add_index :candidate_profiles, :preferred_regions, using: :gin
    add_index :candidate_profiles, :employment_types, using: :gin
  end
end
