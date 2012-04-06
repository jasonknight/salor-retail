class AddReceiptBlurbFooterToSalorConfiguration < ActiveRecord::Migration
  def change
    add_column :salor_configurations, :receipt_blurb_footer, :string

  end
end
