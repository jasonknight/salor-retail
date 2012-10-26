class AddExpiresOnToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :expires_on, :date
  end

  def self.down
    remove_column :items, :expires_on
  end
end
