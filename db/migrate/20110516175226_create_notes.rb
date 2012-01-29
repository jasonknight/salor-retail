class CreateNotes < ActiveRecord::Migration
  def self.up
    create_table :notes do |t|
      t.string :title
      t.text :body
      t.integer :notable_id
      t.string :notable_type
      t.integer :user_id
      t.integer :employee_id

      t.timestamps
    end
  end

  def self.down
    drop_table :notes
  end
end
