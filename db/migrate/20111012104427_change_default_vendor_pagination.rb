class ChangeDefaultVendorPagination < ActiveRecord::Migration
  def self.up
    change_column :configurations, :pagination, :int, {:default => 12}
  end

  def self.down
    change_column :configurations, :pagination, :int, {:default => 10}
  end
end
