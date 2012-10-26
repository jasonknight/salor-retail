class CreateNodeQueues < ActiveRecord::Migration
  def change
    create_table :node_queues do |t|
      t.boolean :handled, :default => false
      t.boolean :send, :default => false
      t.boolean :receive, :default => false
      t.text :payload
      t.string :url
      t.string :source_sku
      t.string :destination_sku
      t.string :owner_type
      t.integer :owner_ir

      t.timestamps
    end
  end
end
