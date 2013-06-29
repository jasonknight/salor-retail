class ChangeOwnerAndEmployeeToUser < ActiveRecord::Migration
  def up
    
    add_column :actions, :model_type, :string
    add_column :actions, :model_id, :integer
    Action.reset_column_information
    Action.connection.execute("UPDATE actions SET model_type=owner_type,model_id=owner_id;")
    
    ActiveRecord::Base.connection.tables.each do |t|      
      begin
        model = t.classify.constantize
        model.reset_column_information
      rescue
        next
      end
      
      if not model.column_names.include? 'user_id' then
        puts "Adding :user_id column :integer to #{model}"
        add_column t, :user_id, :integer
      end
      
      model.reset_column_information

      if model.column_names.include? 'employee_id' then
        puts "Copying employee_id to user_id for #{model}"
        model.connection.execute("UPDATE #{ t } SET user_id=employee_id;")
      end
      
      if model.column_names.include? 'owner_id' then
        puts "Copying owner_id to user_id for #{model}"
        model.connection.execute("UPDATE #{ t } SET user_id=owner_id;")
      end
      
      if model.column_names.include? 'owner_id' then
        puts "Removing column owner_id for #{model}"
        remove_column t, :owner_id
      end
      
      if model.column_names.include? 'owner_type' then
        puts "Removing column owner_type for #{model}"
        remove_column t, :owner_type
      end
      
      if model.column_names.include? 'employee_id' then
        puts "Removing column employee_id for #{model}"
        remove_column t, :employee_id
      end
    end
  end
  
  def down
  end
end
