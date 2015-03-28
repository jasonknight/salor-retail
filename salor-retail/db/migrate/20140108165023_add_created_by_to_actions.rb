class AddCreatedByToActions < ActiveRecord::Migration
  def change
    add_column :actions, :created_by, :integer
  end
end
