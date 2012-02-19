class AddSkuToCustomers < ActiveRecord::Migration
  def change
    begin
    add_column :customers, :sku, :string
    rescue
      puts $!.inspect
    end
    Customer.all.each do |c|
      c.set_sku
      c.save
    end
  end
end
