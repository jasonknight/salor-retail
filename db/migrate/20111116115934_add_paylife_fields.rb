class AddPaylifeFields < ActiveRecord::Migration
  def self.up
    add_column :configurations, :paylife_sa, :string, :default => 'E'
    add_column :configurations, :paylife_version, :string, :default => '1'
    add_column :configurations, :paylife_euro, :string, :defaut => '1'
    add_column :configurations, :paylife_konto, :string, :default => '01'
    add_column :configurations, :paylife_ind, :string, :default => 'U'
    add_column :orders, :p_struct, :text
    add_column :orders, :m_struct, :text
    add_column :orders, :j_struct, :text
  end

  def self.down                                      
    remove_column :configurations, :paylife_sa
    remove_column :configurations, :paylife_version
    remove_column :configurations, :paylife_euro
    remove_column :configurations, :paylife_konto
    remove_column :orders, :p_struct          
    remove_column :orders, :m_struct          
    remove_column :orders, :j_struct          
  end
end
