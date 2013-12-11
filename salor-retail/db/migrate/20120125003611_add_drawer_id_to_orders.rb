class AddDrawerIdToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :drawer_id, :integer
    User.all.each do |u|
      u.orders.each do |o|
        o.update_attribute :drawer_id, u.get_drawer.id
      end
    end
    begin
    Employee.all.each do |e|
      e.orders.each do |o|
        o.update_attribute :drawer_id, e.get_drawer.id
      end
    end
    rescue
      puts "recue: Employee doesn't exist"
    end
  end

  def self.down
    remove_column :orders, :drawer_id
  end
end
