class AddHiddenByDistillerToItems < ActiveRecord::Migration
  def change
    add_column :items, :hidden_by_distiller, :boolean, :default => 0

  end
end
