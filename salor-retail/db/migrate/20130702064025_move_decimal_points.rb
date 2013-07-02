class MoveDecimalPoints < ActiveRecord::Migration
  def up
    remove_column :items, :decimal_points
    add_column :vendors, :gs1_format, :string, :default => "2,5,5"
    add_column :items, :gs1_format, :string, :default => "2,3"
  end

  def down
    add_column :items, :decimal_points, :integer
    remove_column :vendors, :gs1_format
    remove_column :items, :gs1_format
  end
end
