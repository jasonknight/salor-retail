class AddItemNameTranslationsToItems < ActiveRecord::Migration
  def change
    add_column :items, :name_translations, :text
  end
end
