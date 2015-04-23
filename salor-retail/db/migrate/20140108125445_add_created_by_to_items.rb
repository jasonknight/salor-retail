class AddCreatedByToItems < ActiveRecord::Migration
  def change
    add_column :items, :created_by, :integer
  end
end
