class SaasDefaults < ActiveRecord::Migration
  def up
    change_column_default :companies, :mode, 'local'
    Company.where(:mode => nil).update_all :mode => 'local'
  end

  def down
  end
end
