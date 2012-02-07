class AddSkuToCategories < ActiveRecord::Migration
  def change
    add_column :categories, :sku, :string
    Category.all.each do |cat|
      if cat.sku.blank? then
        cat.update_attribute :sku, "#{cat.vendor.name}:#{cat.name}".gsub(/[^a-zA-Z0-9]+/,'')
      end
    end
  end
end
