class AddHashIdToVendors < ActiveRecord::Migration
  def change
    add_column :vendors, :hash_id, :string
  end
end
