class ChangeItemPurchasePrice < ActiveRecord::Migration
  def change
    change_column :items, :purchase_price, :float, :default => 0
  end
end
