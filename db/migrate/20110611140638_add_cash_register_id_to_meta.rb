class AddCashRegisterIdToMeta < ActiveRecord::Migration
  def self.up
    add_column :meta, :cash_register_id, :integer
  end

  def self.down
    remove_column :meta, :cash_register_id
  end
end
