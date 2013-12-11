class CreateDestinations < ActiveRecord::Migration
  def change
    create_table :countries do |t|
      t.string :name
      t.integer :vendor_id
      t.integer :user_id
      t.boolean :hidden

      t.timestamps
    end
  end
end
