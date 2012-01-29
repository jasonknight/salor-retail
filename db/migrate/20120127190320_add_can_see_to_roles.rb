class AddCanSeeToRoles < ActiveRecord::Migration
  def self.up
    Role.create(:name => "see_header").save
  end

  def self.down
  end
end
