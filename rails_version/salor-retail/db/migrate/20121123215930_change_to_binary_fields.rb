class ChangeToBinaryFields < ActiveRecord::Migration
  def up
    change_column :vendors, :receipt_logo_header, :binary
    change_column :vendors, :receipt_logo_footer, :binary
  end

  def down
    change_column :vendors, :receipt_logo_header, :text
    change_column :vendors, :receipt_logo_footer, :text
  end
end
