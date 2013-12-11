class CopyCompanyIdToUserLogins < ActiveRecord::Migration
  def up
    Vendor.all.each do |v|
      puts "Updating company_id of all UserLogins of Vendor #{ v.id }"
      v.user_logins.update_all :company_id => v.company_id
    end
  end

  def down
  end
end
