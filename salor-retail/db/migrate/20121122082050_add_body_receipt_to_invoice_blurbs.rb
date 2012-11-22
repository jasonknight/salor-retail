class AddBodyReceiptToInvoiceBlurbs < ActiveRecord::Migration
  def change
    add_column :invoice_blurbs, :body_receipt, :text
  end
end
