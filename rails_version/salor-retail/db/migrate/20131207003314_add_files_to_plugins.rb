class AddFilesToPlugins < ActiveRecord::Migration
  def change
    add_column :plugins, :files, :text
  end
end
