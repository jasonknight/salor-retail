class CreateHistories < ActiveRecord::Migration
  def change
    create_table :histories do |t|
      t.string :url
      t.string :owner_type
      t.integer :owner_id
      t.string :action_taken
      t.string :model_type
      t.string :ip
      t.integer :sensitivity
      t.integer :model_id
      t.text :changes_made
      t.text :params
      t.timestamps
    end
  end
end
