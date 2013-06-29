class AddCompany < ActiveRecord::Migration
  def up
    c = Company.new
    c.name = "default"
    c.identifier = "default"
    c.save
  end

  def down
  end
end
