class FixUserIdHash < ActiveRecord::Migration
  def up
    if Company.first
      cid = Company.first.id
      UserLogin.update_all :company_id => cid
    end
    
    if Order.last
      vid = Order.last.vendor_id
      UserLogin.update_all :vendor_id => vid
    end
    
    
    
    User.all.each do |u|
      u.set_id_hash
      u.save
    end
  end

  def down
  end
end
