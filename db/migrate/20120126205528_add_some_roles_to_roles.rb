class AddSomeRolesToRoles < ActiveRecord::Migration
  def self.up
    r = Role.find_or_create_by_name(:destroy_order_items)
    r.save
  end

  def self.down
  end
end
