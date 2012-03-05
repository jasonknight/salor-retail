class AddCategoryIdToButton < ActiveRecord::Migration
  def change
    rename_column :buttons, :category, :old_category_name
    add_column :buttons, :category_id, :integer

    add_column :buttons, :color, :string

    add_column :buttons, :position, :integer
    Button.all.each do |b|
       cat = Category.find_or_create_by_name(b.old_category_name)
       cat.update_attribute :vendor_id, b.vendor_id
       cat.update_attribute :button_category, true
       b.update_attribute :category_id, cat.id
    end
  end
end
