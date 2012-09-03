class FixDiscountsHiddenField < ActiveRecord::Migration
  def up
    change_column_default :discounts,:hidden,false
  end

  def down
  end
end
