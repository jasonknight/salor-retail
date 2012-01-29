class AddIsBuybackToButtons < ActiveRecord::Migration
  def self.up
    add_column :buttons, :is_buyback, :boolean, :default => false
    Button.all.each do |b|
      i = Item.find_by_sku b.sku
      if i and i.default_buyback then
        b.update_attribute :is_buyback,true
      end
    end
  end

  def self.down
    remove_column :buttons, :is_buyback
  end
end
