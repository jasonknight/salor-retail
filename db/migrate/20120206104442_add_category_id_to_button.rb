class AddCategoryIdToButton < ActiveRecord::Migration
  def change
    add_column :buttons, :category_id, :integer

    add_column :buttons, :color, :string

    rename_column :buttons, :weight, :position

  end
end
