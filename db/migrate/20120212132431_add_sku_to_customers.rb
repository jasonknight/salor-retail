class AddSkuToCustomers < ActiveRecord::Migration
  def change
    begin
    add_column :customers, :sku, :string
    rescue
      puts $!.inspect
    end
    begin
    Customer.all.each do |c|
      #c.set_sku
      c.update_attribute :sku, "#{c.company_name}#{c.first_name}#{c.last_name}".gsub(/[^a-zA-Z0-9]+/,'')
      #c.save
    end
    rescue
      puts $!.inspect
    end
  end
end
