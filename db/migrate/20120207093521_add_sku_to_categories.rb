class AddSkuToCategories < ActiveRecord::Migration
  def change
    begin
    add_column :categories, :sku, :string
    rescue
      puts $!.inspect
    end
    Category.all.each do |cat|
      if cat.sku.blank? and not cat.vendor.nil? then
        cat.update_attribute :sku, "#{cat.vendor.name}:#{cat.name}".gsub(/[^a-zA-Z0-9]+/,'')
      end
    end
  end
end
