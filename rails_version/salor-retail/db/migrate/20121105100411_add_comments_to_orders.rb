class AddCommentsToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :invoice_comment, :text
    add_column :orders, :delivery_note_comment, :text
  end
end
