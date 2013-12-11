class AddFieldToSalorConfigurations < ActiveRecord::Migration
  def change
    add_column :salor_configurations, :csv_categories, :boolean

    add_column :salor_configurations, :csv_buttons, :boolean

    add_column :salor_configurations, :csv_discounts, :boolean

    add_column :salor_configurations, :csv_customers, :boolean

    add_column :salor_configurations, :csv_loyalty_cards, :boolean

  end
end
