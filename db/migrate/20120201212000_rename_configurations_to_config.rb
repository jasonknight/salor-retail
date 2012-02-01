class RenameConfigurationsToConfig < ActiveRecord::Migration
  def up
  	  begin
  	  	  rename_table :configurations, :salor_configurations
	  rescue
	  	  rename_table :configs, :salor_configurations  
	  end
  end

  def down
  end
end
