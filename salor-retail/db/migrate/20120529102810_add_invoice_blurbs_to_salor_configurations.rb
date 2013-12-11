class AddInvoiceBlurbsToSalorConfigurations < ActiveRecord::Migration
  def change
    add_column :salor_configurations, :invoice_blurb, :text
    add_column :salor_configurations, :invoice_blurb_footer, :text
  end
end
