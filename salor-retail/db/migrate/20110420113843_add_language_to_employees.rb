class AddLanguageToEmployees < ActiveRecord::Migration
  def self.up
    add_column :employees, :language, :string
  end

  def self.down
    remove_column :employees, :language
  end
end
