class CleanupConfigurations < ActiveRecord::Migration
  def up
    drop_table :salor_configurations
    drop_table :sessions
    drop_table :paylife_structs
    drop_table :meta
    remove_column :orders, :p_result
    remove_column :orders, :p_text
    remove_column :orders, :p_struct
    remove_column :orders, :m_struct
    remove_column :orders, :j_struct
    remove_column :orders, :j_text
    remove_column :orders, :j_ind
    remove_column :orders, :bk_msgs_received
  end

  def down
  end
end
