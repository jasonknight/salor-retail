class AddTaxProfileIdToOrderItems < ActiveRecord::Migration
  def self.up
    add_column :order_items, :tax_profile_id, :integer
  end

  def self.down
    remove_column :order_items, :tax_profile_id
  end
end
