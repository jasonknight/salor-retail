class AddLicenseAcceptedToSalorConfigurations < ActiveRecord::Migration
  def change
    add_column :salor_configurations, :license_accepted, :boolean, :default => false

  end
end
