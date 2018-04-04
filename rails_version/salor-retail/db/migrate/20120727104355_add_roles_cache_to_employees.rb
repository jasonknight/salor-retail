class AddRolesCacheToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :role_cache, :string
    add_column :users, :role_cache, :string
    begin
    Employee.all.each do |e|
      e.set_role_cache
      e.save
    end
    rescue
      puts "recue: Employee doesn't exist"
    end
  end
end
