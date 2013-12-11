class AddVendorIdToItemTypes < ActiveRecord::Migration
  def change
    add_column :item_types, :vendor_id, :integer
  end
end
