class AddHiddenFieldsToAllModels < ActiveRecord::Migration
  def up
    ActiveRecord::Base.connection.tables.each do |t|      
      begin
        model = t.classify.constantize
        model.reset_column_information
      rescue
        next
      end

      if not model.column_names.include? 'hidden' then
        puts "Adding :hidden column :boolean to #{model}"
        add_column model.table_name.to_sym, :hidden, :boolean
      else
        puts "Changing :hidden column to :boolean for #{model}"
        change_column model.table_name.to_sym, :hidden, :boolean
      end
      
      if not model.column_names.include? 'hidden_by' then
        puts "Adding :hidden_by column :integer to #{model}"
        add_column model.table_name.to_sym, :hidden_by, :integer
      end
      
      if not model.column_names.include? 'hidden_at' then
        puts "Adding :hidden_at column :datetime to #{model}"
        add_column model.table_name.to_sym, :hidden_at, :datetime
      end
    end
  end
  
  def down
  end
end
