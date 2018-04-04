class ChangeChildIdDefaultInItems < ActiveRecord::Migration
  def up
    change_column_default :items, :child_id, nil
    Item.where(:child_id => 0).update_all :child_id => nil
  end

  def down
    change_column_default :items, :child_id, 0
  end
end
