class ChangeIspart < ActiveRecord::Migration
  def up
    change_column :items, :is_part, :boolean
  end

  def down
  end
end
