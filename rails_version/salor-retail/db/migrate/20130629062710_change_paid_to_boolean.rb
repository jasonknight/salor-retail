class ChangePaidToBoolean < ActiveRecord::Migration
  def up
    change_column :orders, :paid, :boolean
  end

  def down
    change_column :orders, :paid, :integer
  end
end
