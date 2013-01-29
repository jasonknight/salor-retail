class AddVendorIdToItemStocks < ActiveRecord::Migration
  def change
    add_column :item_stocks, :vendor_id, :integer
  end
end
