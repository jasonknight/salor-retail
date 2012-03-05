class FixChildIdOnItems < ActiveRecord::Migration
  def up
    change_column :items, :child_id, :integer, :default => 0
    Item.connection.execute("update items set child_id = 0 where child_id IS NULL;")
  end

  def down
  end
end
