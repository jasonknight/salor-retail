class ChangeReceiptsText < ActiveRecord::Migration
  def up
    change_table :receipts do |t|
      t.change :content, :binary
    end
  end

  def down
  end
end
