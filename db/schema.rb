# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_07_20_200557) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "candidate_documents", force: :cascade do |t|
    t.bigint "candidate_profile_id", null: false
    t.integer "document_type", default: 0, null: false
    t.string "original_filename"
    t.string "content_type"
    t.bigint "byte_size"
    t.integer "parsing_status", default: 0, null: false
    t.datetime "parsed_at"
    t.text "error_message"
    t.jsonb "parsed_data", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_profile_id"], name: "index_candidate_documents_on_candidate_profile_id"
    t.index ["parsing_status"], name: "index_candidate_documents_on_parsing_status"
  end

  create_table "candidate_languages", force: :cascade do |t|
    t.bigint "candidate_profile_id", null: false
    t.bigint "language_id", null: false
    t.string "level"
    t.integer "source", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_profile_id", "language_id"], name: "index_candidate_languages_on_profile_and_language", unique: true
    t.index ["candidate_profile_id"], name: "index_candidate_languages_on_candidate_profile_id"
    t.index ["language_id"], name: "index_candidate_languages_on_language_id"
  end

  create_table "candidate_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "phone_number"
    t.string "city"
    t.string "country"
    t.integer "job_function"
    t.string "preferred_regions", default: [], null: false, array: true
    t.integer "max_travel_time_minutes"
    t.string "transport_types", default: [], null: false, array: true
    t.integer "search_status"
    t.text "reason_for_looking"
    t.string "employment_types", default: [], null: false, array: true
    t.integer "desired_gross_salary"
    t.integer "desired_percentage"
    t.decimal "average_daily_revenue", precision: 10, scale: 2
    t.integer "big_registration_status"
    t.string "big_number"
    t.decimal "years_of_experience", precision: 4, scale: 1
    t.string "available_working_days", default: [], null: false, array: true
    t.date "available_from"
    t.string "notice_period"
    t.text "motivation_for_employer"
    t.text "internal_notes"
    t.text "professional_summary"
    t.string "extracted_fields", default: [], null: false, array: true
    t.datetime "consent_given_at"
    t.datetime "onboarding_completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_candidate_profiles_on_email"
    t.index ["employment_types"], name: "index_candidate_profiles_on_employment_types", using: :gin
    t.index ["preferred_regions"], name: "index_candidate_profiles_on_preferred_regions", using: :gin
    t.index ["user_id"], name: "index_candidate_profiles_on_user_id"
  end

  create_table "candidate_skills", force: :cascade do |t|
    t.bigint "candidate_profile_id", null: false
    t.bigint "skill_id"
    t.string "skill_name_suggestion"
    t.integer "source", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_profile_id", "skill_id"], name: "index_candidate_skills_on_profile_and_skill", unique: true, where: "(skill_id IS NOT NULL)"
    t.index ["candidate_profile_id"], name: "index_candidate_skills_on_candidate_profile_id"
    t.index ["skill_id"], name: "index_candidate_skills_on_skill_id"
  end

  create_table "educations", force: :cascade do |t|
    t.bigint "candidate_profile_id", null: false
    t.string "institution"
    t.string "study"
    t.string "city_country"
    t.integer "level"
    t.date "start_date"
    t.date "end_date"
    t.integer "source", default: 0, null: false
    t.boolean "needs_review", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_profile_id"], name: "index_educations_on_candidate_profile_id"
  end

  create_table "languages", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_languages_on_name", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "skills", force: :cascade do |t|
    t.string "name", null: false
    t.integer "function_group", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "function_group"], name: "index_skills_on_name_and_function_group", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 0, null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "work_experiences", force: :cascade do |t|
    t.bigint "candidate_profile_id", null: false
    t.string "job_title"
    t.string "company_name"
    t.text "responsibilities"
    t.date "start_date"
    t.date "end_date"
    t.boolean "current_job", default: false, null: false
    t.integer "source", default: 0, null: false
    t.boolean "needs_review", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_profile_id"], name: "index_work_experiences_on_candidate_profile_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "candidate_documents", "candidate_profiles"
  add_foreign_key "candidate_languages", "candidate_profiles"
  add_foreign_key "candidate_languages", "languages"
  add_foreign_key "candidate_profiles", "users"
  add_foreign_key "candidate_skills", "candidate_profiles"
  add_foreign_key "candidate_skills", "skills"
  add_foreign_key "educations", "candidate_profiles"
  add_foreign_key "sessions", "users"
  add_foreign_key "work_experiences", "candidate_profiles"
end
