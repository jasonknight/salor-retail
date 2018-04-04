class CreatePlugins < ActiveRecord::Migration
  def change
    create_table :plugins do |t|
      t.string :name
      t.string :filename
      t.string :base_path
      t.references :company
      t.references :vendor
      t.boolean :hidden
      t.integer :hidden_by
      t.datetime :hidden_at

      t.timestamps
    end
    add_index :plugins, :company_id
    add_index :plugins, :vendor_id
    add_index :plugins, :hidden_by
  end
end
