class AddVendorIdToShippers < ActiveRecord::Migration
  def change
    add_column :shippers, :vendor_id, :integer
  end
end
