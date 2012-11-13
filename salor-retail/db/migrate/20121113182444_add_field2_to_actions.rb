class AddField2ToActions < ActiveRecord::Migration
  def change
    add_column :actions, :field2, :string
    add_column :actions, :value2, :float
  end
end
