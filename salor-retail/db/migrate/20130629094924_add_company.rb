class AddCompany < ActiveRecord::Migration
  def up
    if Vendor.all.any?
      c = Company.new
      c.name = "default"
      c.identifier = "default"
      c.save
    end
  end

  def down
  end
end
