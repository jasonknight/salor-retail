class AddSkusToModels < ActiveRecord::Migration
  def self.up
    begin
    add_column :tax_profiles, :sku, :string
    add_column :discounts, :sku, :string
    add_column :vendors, :sku, :string
    add_column :shippers, :sku, :string
    add_column :shipments, :sku, :string
    add_column :orders, :sku, :string
    rescue
      puts "Failed to add columns because of: " + $!.inspect
    end
    Vendor.all.each do |vendor|
      if vendor.sku.empty? then
        vendor.update_attribute :sku, vendor.name.upcase.gsub(/\s+/,'')
      end
      vendor.orders.each do |o|
        if o.sku.empty? then
          o.update_attribute :sku,"#{vendor.sku}:#{o.class}:#{o.id}"
        end
      end
      vendor.tax_profiles.each do |tp|
        if tp.sku.empty? then
          tp.update_attribute :sku,"#{vendor.sku}:#{tp.class}:#{tp.id}"
        end
      end
      vendor.shippers.each do |s|
        if s.sku.empty? then
          s.update_attribute :sku,"#{vendor.sku}:#{s.class}:#{s.id}"
        end
      end
      vendor.shipments.each do |s|
        if s.sku.empty? then
         s.update_attribute :sku,"#{vendor.sku}:#{s.class}:#{s.id}"
        end
      end
      vendor.discounts.each do |s|
        if s.sku.empty? then
         s.update_attribute :sku,"#{vendor.sku}:#{s.class}:#{s.id}"
        end
      end
    end
  end

  def self.down
    remove_column :tax_profiles, :sku
    remove_column :discounts, :sku
    remove_column :vendors, :sku
    remove_column :shippers, :sku
    remove_column :shipments, :sku
    remove_column :orders, :sku
  end
end
