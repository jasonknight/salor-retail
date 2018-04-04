class RenameEmployeeInUserLogin < ActiveRecord::Migration
  def change
    rename_column :user_logins, :employee_id, :user_id
  end
end
