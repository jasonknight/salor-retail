class CreateInvoiceBlurbs < ActiveRecord::Migration
  def change
    create_table :invoice_blurbs do |t|
      t.string :lang
      t.text :body
      t.boolean :is_header
      t.references :vendor
      t.timestamps
    end
  end
end
