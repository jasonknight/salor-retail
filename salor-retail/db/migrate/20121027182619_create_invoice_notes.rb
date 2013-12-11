class CreateInvoiceNotes < ActiveRecord::Migration
  def change
    create_table :invoice_notes do |t|
      t.string :name
      t.text :note_header
      t.text :note_footer
      t.integer :origin_country_id
      t.integer :destination_country_id
      t.integer :vendor_id
      t.integer :user_id
      t.boolean :hidden
      t.integer :sale_type_id

      t.timestamps
    end
  end
end
