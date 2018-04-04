class FixHiddenItems < ActiveRecord::Migration
  def self.up
    Item.where("hidden = 1").each do |item|
      puts item.sku
      item.update_attribute(:sku, rand(999).to_s + 'OLD:' + item.sku) if not item.sku.include? 'OLD:'
    end
  end

  def self.down
  end
end
