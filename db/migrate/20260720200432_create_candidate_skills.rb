class CreateCandidateSkills < ActiveRecord::Migration[8.0]
  def change
    create_table :candidate_skills do |t|
      t.references :candidate_profile, null: false, foreign_key: true
      t.references :skill, null: true, foreign_key: true
      t.string :skill_name_suggestion
      t.integer :source, null: false, default: 0

      t.timestamps
    end

    add_index :candidate_skills, [ :candidate_profile_id, :skill_id ], unique: true, where: "skill_id IS NOT NULL", name: "index_candidate_skills_on_profile_and_skill"
  end
end
