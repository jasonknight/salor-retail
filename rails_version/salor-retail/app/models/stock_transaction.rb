class StockTransaction < ActiveRecord::Base
  belongs_to :company
  belongs_to :vendor
  belongs_to :order
  belongs_to :user
  belongs_to :from, :polymorphic => true
  belongs_to :to, :polymorphic => true

  validates_presence_of :vendor_id, :company_id
  
  
  # This creates a StockTransaction and acutally does the incrementing/decrementing on the model. "model1" can be a StockItem or an Item (it must respond to a quantity setter). "model2" only serves for labelling purposes of the StockTransaction. It can be any model that logically can send or receive a quantity (e.g. ShipmentItem, StockItem, Item, Order, etc.)
  def self.transact(diff, model1, model2)
    SalorBase.log_action "ItemStock", "[transact()] Creating new StockTransaction. model1 is #{ model1.class.to_s } #{ model1.id }, model2 is #{ model2.class.to_s } #{ model2.id }", :cyan
    
    st = StockTransaction.new
    st.company = model1.company
    st.vendor = model1.vendor
    st.quantity = diff
    st.to = model1
    st.from = model2
    st.to_quantity = model1.quantity # this is the quantity before the modification below, for documentation purposes.
    
    case model2.class.to_s
    when 'ItemStock'
      st.from_quantity = model2.quantity
    when 'Item'
      st.from_quantity = model2.quantity
    when 'ShipmentItem'
      st.from_quantity = model2.quantity.to_f - model2.in_stock_quantity.to_f
    end
    
    SalorBase.log_action "ItemStock", "[transact()] model1 (#{ model1.class.to_s } ID #{ model1.id }). Adding #{ diff } to it", :cyan
    
    model1.quantity += diff
    result = model1.save
    
    if result != true
      raise "Could not save #{ model1.class.to_s } #{ model1.id } because #{ model1.errors.messages }"
    end

    st.save
  end
end
