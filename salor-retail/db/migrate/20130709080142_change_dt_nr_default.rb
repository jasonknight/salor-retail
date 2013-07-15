class ChangeDtNrDefault < ActiveRecord::Migration
  def up
    change_column_default :vendors, :largest_drawer_transaction_number, 0
  end

  def down
  end
end
