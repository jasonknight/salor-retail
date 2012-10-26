class AddFieldsToErrors < ActiveRecord::Migration
  def self.up
    add_column :errors, :url, :string
    add_column :errors, :referer, :string
  end

  def self.down
    remove_column :errors, :referer
    remove_column :errors, :url
  end
end
