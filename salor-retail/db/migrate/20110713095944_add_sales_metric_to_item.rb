class AddSalesMetricToItem < ActiveRecord::Migration
  def self.up
    add_column :items, :sales_metric, :string
  end

  def self.down
    remove_column :items, :sales_metric
  end
end
