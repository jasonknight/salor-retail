class AddCurrentOrderIdToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :current_order_id, :integer
  end
end
