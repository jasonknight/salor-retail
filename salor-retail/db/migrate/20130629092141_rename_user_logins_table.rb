class RenameUserLoginsTable < ActiveRecord::Migration
  def change
    rename_table :users_roles, :roles_users
  end
end
