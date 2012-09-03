class AddDefaultBuybackToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :default_buyback, :boolean, :default => false
  end

  def self.down
    remove_column :items, :default_buyback
  end
end
