class AddEmployeeToOrderItems < ActiveRecord::Migration
  def change
    add_column :order_items, :employee_id, :integer
    OrderItem.connection.execute("update order_items as oi set oi.employee_id = (select employee_id from orders where order_id = oi.order_id)")
  end
end
