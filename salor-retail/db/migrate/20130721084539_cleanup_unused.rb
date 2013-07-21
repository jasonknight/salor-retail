class CleanupUnused < ActiveRecord::Migration
  def up
    # this file has been renamed to a later date, that is the reason for begin/rescue/end
    begin
    remove_column :order_items, :refund_payment_method_internal_type
    remove_column :payment_method_items, :internal_type
    rescue
    end
  end

  def down
  end
end
