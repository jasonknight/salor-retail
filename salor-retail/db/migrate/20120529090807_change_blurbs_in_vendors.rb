class ChangeBlurbsInVendors < ActiveRecord::Migration
  def up
    change_column :salor_configurations, :receipt_blurb_footer, :text
  end

  def down
  end
end
