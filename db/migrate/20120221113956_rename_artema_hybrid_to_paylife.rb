class RenameArtemaHybridToPaylife < ActiveRecord::Migration
  def up
    rename_column :cash_registers, :artema_hybrid, :paylife
  end

  def down
  end
end
