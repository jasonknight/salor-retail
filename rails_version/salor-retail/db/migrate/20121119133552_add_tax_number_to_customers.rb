class AddTaxNumberToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :tax_number, :string
  end
end
