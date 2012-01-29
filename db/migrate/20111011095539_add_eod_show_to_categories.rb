class AddEodShowToCategories < ActiveRecord::Migration
  def self.up
    add_column :categories, :eod_show, :boolean, :default => false
  end

  def self.down
    remove_column :categories, :eod_show
  end
end
