class ChangeIsBusyDefault < ActiveRecord::Migration
  def up
    change_column_default :nodes, :is_busy, 0
  end

  def down
  end
end
