class SetDefaultWeightForItems < ActiveRecord::Migration
  def up
    change_column_default :items, :weight_metric, 'g'
  end

  def down
  end
end
