class CreateEducations < ActiveRecord::Migration[8.0]
  def change
    create_table :educations do |t|
      t.references :candidate_profile, null: false, foreign_key: true
      t.string :institution
      t.string :study
      t.string :city_country
      t.integer :level
      t.date :start_date
      t.date :end_date
      t.integer :source, null: false, default: 0
      t.boolean :needs_review, null: false, default: false

      t.timestamps
    end
  end
end
