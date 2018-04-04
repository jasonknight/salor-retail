class AddUnpaidInvoiceToOrders < ActiveRecord::Migration
  def change
    begin
      add_column :orders, :unpaid_invoice, :boolean, :default => false
    rescue
      puts $!.inspect
    end
  end
end
