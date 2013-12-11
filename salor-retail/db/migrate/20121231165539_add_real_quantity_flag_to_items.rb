class AddRealQuantityFlagToItems < ActiveRecord::Migration
  def change
    add_column :items, :real_quantity_updated, :boolean
    Item.connection.execute("update items set real_quantity_updated = true where real_quantity > 0")
  end
end
