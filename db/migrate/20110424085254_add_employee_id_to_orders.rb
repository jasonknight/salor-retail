class AddEmployeeIdToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :employee_id, :integer
  end

  def self.down
    remove_column :orders, :employee_id
  end
end
