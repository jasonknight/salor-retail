class CreateEmployeesRoles < ActiveRecord::Migration
  def self.up
    create_table :employees_roles, :id => false do |t|
      t.references :employee
      t.references :role
    end
  end

  def self.down
    drop_table :employees_roles
  end
end
