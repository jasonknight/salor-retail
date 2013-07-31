class AddPaginationToVendors < ActiveRecord::Migration
  def change
    add_column :vendors, :pagination_invoice_one, :integer, :default => 20
    add_column :vendors, :pagination_invoice_other, :integer, :default => 30
  end
end
