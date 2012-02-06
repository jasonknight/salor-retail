class AddCategoryIdToButton < ActiveRecord::Migration
  def change
    add_column :buttons, :category_id, :integer

    add_column :buttons, :color, :string

  end
end
