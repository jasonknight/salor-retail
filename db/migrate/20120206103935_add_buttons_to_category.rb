class AddButtonsToCategory < ActiveRecord::Migration
  def change
    add_column :categories, :button_category, :boolean

    add_column :categories, :position, :integer

    add_column :categories, :color, :string

  end
end
