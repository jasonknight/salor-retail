class AddImportFormatToShippers < ActiveRecord::Migration
  def change
    add_column :shippers, :import_format, :string
  end
end
