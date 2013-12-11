class RemoveIndexes < ActiveRecord::Migration
  def up
    remove_index :users, :name => "index_employees_on_email"
    remove_index :users, :name => "index_employees_on_reset_password_token"
    remove_index :users, :name => "index_employees_on_user_id"
    remove_index :users, :name => "index_employees_on_vendor_id"
    remove_index :users_roles, :name => "index_employees_roles_on_employee_id_and_role_id"
    remove_index :user_logins, :name => "index_employee_logins_on_vendor_id"
  end

  def down
  end
end
