class ChangeUsers < ActiveRecord::Migration
  def self.up
    User.all.each do |u|
      u.update_attribute :password,u.username
    end
    begin
    Employee.all.each do |e|
      e.update_attribute :password,e.username
    end
    rescue
      puts "recue: Employee doesn't exist"
    end
    add_column :users, :last_path, :string, :default => "/vendors"
    add_column :employees, :last_path, :string, :default => "/cash_registers"
  end

  def self.down
    remove_column :users, :last_path 
    remove_column :employees, :last_path
  end
end
