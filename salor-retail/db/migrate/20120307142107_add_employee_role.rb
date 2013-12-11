class AddEmployeeRole < ActiveRecord::Migration
  def up
    r = Role.new(:name => :employee)
    r.save
  end

  def down
  end
end
