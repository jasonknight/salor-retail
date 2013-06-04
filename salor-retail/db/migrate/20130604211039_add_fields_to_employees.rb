class AddFieldsToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :telephone, :string
    add_column :employees, :cellphone, :string
    add_column :employees, :address, :text
  end
end
