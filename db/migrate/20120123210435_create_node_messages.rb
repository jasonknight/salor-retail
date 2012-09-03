class CreateNodeMessages < ActiveRecord::Migration
  def self.up
    create_table :node_messages do |t|
      t.string :source_sku
      t.string :dest_sku
      t.string :mdhash

      t.timestamps
    end
  end

  def self.down
    drop_table :node_messages
  end
end
