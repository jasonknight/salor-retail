class NewRoles < ActiveRecord::Migration
  def self.up
    [ :transaction_tags, :buttons,:stock_locations].each do |r|
      [:index,:edit,:destroy,:create,:update,:show].each do |a|
        role = Role.new(:name => a.to_s + '_' + r.to_s)
        role.save
      end
      role = Role.new(:name => 'any_' + r.to_s)
      role.save
    end
  end

  def self.down
  end
end
