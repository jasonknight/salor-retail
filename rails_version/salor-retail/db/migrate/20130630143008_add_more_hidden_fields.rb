class AddMoreHiddenFields < ActiveRecord::Migration
  def change
    change_column :users, :hidden, :boolean
    add_column :users, :hidden_at, :datetime
    add_column :users, :hidden_by, :integer
    remove_column :users, :user_id
    
    add_column :user_logins, :company_id, :integer
    add_column :user_logins, :hidden, :boolean
    add_column :user_logins, :hidden_by, :integer
    add_column :user_logins, :hidden_at, :datetime
  end
end
