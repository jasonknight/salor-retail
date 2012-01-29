class AddRoleCangePricesToRoles < ActiveRecord::Migration
  def self.up
  	  r = Role.find_or_create_by_name :change_prices
  	  r.save
  end

  def self.down
  end
end
