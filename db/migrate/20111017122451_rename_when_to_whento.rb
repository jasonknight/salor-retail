class RenameWhenToWhento < ActiveRecord::Migration
  def self.up
    rename_column :actions, :when, :whento
  end

  def self.down
  end
end
