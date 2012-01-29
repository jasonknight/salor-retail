class CreateTenderMethods < ActiveRecord::Migration
  def self.up
    create_table :tender_methods do |t|
      t.string :name
      t.string :internal_type
      t.references :vendor

      t.timestamps
    end
    [ :actions,:tender_methods].each do |r|
      [:index,:edit,:destroy,:create,:update,:show].each do |a|
        role = Role.new(:name => a.to_s + '_' + r.to_s)
        role.save
      end
      role = Role.new(:name => 'any_' + r.to_s)
      role.save
    end
  end

  def self.down
    drop_table :tender_methods
  end
end
