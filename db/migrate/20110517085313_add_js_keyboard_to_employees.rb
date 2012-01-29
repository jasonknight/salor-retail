class AddJsKeyboardToEmployees < ActiveRecord::Migration
  def self.up
    add_column :employees, :js_keyboard, :boolean, :default => false
  end

  def self.down
    remove_column :employees, :js_keyboard
  end
end
