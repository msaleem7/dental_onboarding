class CreateCandidateLanguages < ActiveRecord::Migration[8.0]
  def change
    create_table :candidate_languages do |t|
      t.references :candidate_profile, null: false, foreign_key: true
      t.references :language, null: false, foreign_key: true
      t.string :level
      t.integer :source, null: false, default: 0

      t.timestamps
    end

    add_index :candidate_languages, [ :candidate_profile_id, :language_id ], unique: true, name: "index_candidate_languages_on_profile_and_language"
  end
end
