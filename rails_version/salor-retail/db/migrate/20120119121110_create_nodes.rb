class CreateNodes < ActiveRecord::Migration
  def self.up
    create_table :nodes do |t|
      t.string :name
      t.string :sku
      t.string :token
      t.string :node_type
      t.string :url
      t.boolean :is_self
      t.text :accepted_ips
      t.references :vendor

      t.timestamps
    end
  end

  def self.down
    drop_table :nodes
  end
end
