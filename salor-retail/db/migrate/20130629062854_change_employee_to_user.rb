class ChangeEmployeeToUser < ActiveRecord::Migration
  def up
    drop_table :users
    rename_table :employees, :users
    rename_table :employee_logins, :user_logins
    rename_column :employees_roles, :employee_id, :user_id
    rename_table :employees_roles, :users_roles
  end

  def down
  end
end
