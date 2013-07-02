class MoveDecimalPoints < ActiveRecord::Migration
  def up
    remove_column :items, :decimal_points
    add_column :vendors, :gs1_format, :string, :default => "2|5|2|3"
  end

  def down
    add_column :items, :decimal_points, :integer
    remove_column :vendors, :gs1_format
  end
end
