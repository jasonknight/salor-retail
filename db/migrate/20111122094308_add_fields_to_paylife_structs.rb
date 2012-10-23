class AddFieldsToPaylifeStructs < ActiveRecord::Migration
  def self.up
    add_column :paylife_structs, :sa, :string
    add_column :paylife_structs, :ind, :string
  end

  def self.down
    remove_column :paylife_structs, :ind
    remove_column :paylife_structs, :sa
  end
end
