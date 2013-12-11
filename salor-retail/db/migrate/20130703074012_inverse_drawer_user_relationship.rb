class InverseDrawerUserRelationship < ActiveRecord::Migration
  def up
    add_column :users, :drawer_id, :integer
    
    # user belongs_to drawer instead of drawer belongs_to user. this is needed for more convenient payment_method_item transformations in the next migration, since uses_drawer_id is part of users.
    
    Vendor.connection.execute("UPDATE users,drawers SET users.drawer_id = drawers.id WHERE drawers.user_id = users.id")
    
    remove_column :drawers, :user_id
  end

  def down
  end
end
