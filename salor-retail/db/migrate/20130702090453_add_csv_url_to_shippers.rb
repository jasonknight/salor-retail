class AddCsvUrlToShippers < ActiveRecord::Migration
  def change
    add_column :shippers, :csv_url, :string
  end
end
