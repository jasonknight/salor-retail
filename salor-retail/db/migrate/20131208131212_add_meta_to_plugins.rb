class AddMetaToPlugins < ActiveRecord::Migration
  def change
    add_column :plugins, :meta, :text
  end
end
