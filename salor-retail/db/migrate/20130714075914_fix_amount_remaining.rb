class FixAmountRemaining < ActiveRecord::Migration
  def up
    # in the old code, all Items always had the price copied over. This makes queries more difficult, so we set it to 0 for non-giftcards
    Item.where("behavior != 'gift_card'").update_all :gift_card_amount_cents => 0
    OrderItem.where("behavior != 'gift_card'").update_all :gift_card_amount_cents => 0
  end

  def down
  end
end
