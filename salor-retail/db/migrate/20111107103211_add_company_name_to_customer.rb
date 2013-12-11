class AddCompanyNameToCustomer < ActiveRecord::Migration
  def self.up
    add_column :customers, :company_name, :string
  end

  def self.down
    remove_column :customers, :company_name
  end
end
