class CreateLanguages < ActiveRecord::Migration[8.0]
  def change
    create_table :languages do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :languages, :name, unique: true
  end
end
