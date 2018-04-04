class CopyUrlToCashRegisters < ActiveRecord::Migration
  def up
    
    v = Order.last.vendor if Order.last
    v ||= Vendor.first
    
    if v
      url = v.url
      CashRegister.update_all :ip => url
    end
    remove_column :vendors, :url
  end

  def down
  end
end
