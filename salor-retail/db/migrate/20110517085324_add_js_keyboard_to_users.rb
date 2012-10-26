class AddJsKeyboardToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :js_keyboard, :boolean, :default => false
  end

  def self.down
    remove_column :users, :js_keyboard
  end
end
