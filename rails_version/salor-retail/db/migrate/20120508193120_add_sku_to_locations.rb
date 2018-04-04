class AddSkuToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :sku, :string, :default => ''
    Location.all.each do |l|
      if l.sku.blank? then
        l.set_sku
        l.save
      end
    end
  end
end
