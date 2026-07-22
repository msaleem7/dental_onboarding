class CreateSkills < ActiveRecord::Migration[8.0]
  def change
    create_table :skills do |t|
      t.string :name, null: false
      t.integer :function_group, null: false

      t.timestamps
    end

    add_index :skills, [ :name, :function_group ], unique: true
  end
end
