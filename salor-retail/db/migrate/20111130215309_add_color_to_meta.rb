class AddColorToMeta < ActiveRecord::Migration
  def self.up
    begin
    add_column :meta, :color, :string
    colors = ['#8d7700','#007272','#0a256a','#6a0a67','#1a4d08']
    Employee.all.each do |emp|
      emp.make_valid
      emp.meta.update_attribute :color, colors.shift if colors.any?
    end
    rescue
      puts "recue: Employee doesn't exist"
    end
  end

  def self.down
    remove_column :meta, :color
  end
end
