class AddClearAndDeleteToRoles < ActiveRecord::Migration
  def self.up
    [:clear_orders, :remove_order_items].each do |r|
      role = Role.find_or_create_by_name r.to_s
      role.save
    end
  end

  def self.down
    [:clear_orders, :remove_order_items].each do |r|
      role = Role.find_by_name r.to_s
      role.destroy if role
    end
  end
end
