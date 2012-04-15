class AddIsBusyToNodes < ActiveRecord::Migration
  def change
    add_column :nodes, :is_busy, :boolean

  end
end
