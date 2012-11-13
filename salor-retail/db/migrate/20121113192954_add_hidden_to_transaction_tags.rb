class AddHiddenToTransactionTags < ActiveRecord::Migration
  def change
    add_column :transaction_tags, :hidden, :boolean
  end
end
