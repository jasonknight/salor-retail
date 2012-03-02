class CreateCues < ActiveRecord::Migration
  def change
    create_table :cues do |t|
      t.boolean :is_handled, :default => false
      t.boolean :to_send, :default => false
      t.boolean :to_receive, :default => false
      t.text :payload
      t.string :url
      t.string :source_sku
      t.string :destination_sku
      t.string :owner_type
      t.integer :owner_id
      t.timestamps
    end
  end
end
