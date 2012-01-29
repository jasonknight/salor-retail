module OrdersHelper

  def calculate_order_sums(order)
      sum_taxes = Hash.new
      TaxProfile.all.each { |t| sum_taxes[t.id] = 0 }
      subtotal = 0.0
      discount_subtotal = 0.0
      rebate_subtotal = 0.0
      refund_subtotal = 0.0
      coupon_subtotal = 0.0
      list_of_items = ''
      order.order_items.each do |oi|
        item_price = case oi.behavior
          when 'normal' then   oi.price
          when 'gift_card' then oi.activated ? - oi.total : oi.total
          when 'coupon' then oi.order_item ? - oi.order_item.coupon_amount : 0
        end

        item_price = -oi.price if order.buy_order

        if oi.behavior == 'coupon' and oi.item.coupon_type == 1 and oi.order_item # percent coupon
          item_price = - oi.order_item.price * oi.price / 100.0
          item_total = item_price * oi.quantity
        elsif oi.behavior == 'coupon' and oi.item.coupon_type == 3 and oi.order_item # b1g1 coupon
          item_total = oi.order_item.quantity >= (2 * oi.quantity) ? (- oi.order_item.price * oi.quantity) : 0.0
        else
          item_price = oi.item.base_price if oi.discount_applied
          item_total = item_price * oi.quantity
        end

        if oi.refunded then
          refund_subtotal -= item_total
          item_price = 0.0
          item_total = 0.0
        end

        sum_taxes[oi.tax_profile.id] += item_total

        name = oi.item.name

        if oi.behavior == 'coupon' and oi.item.coupon_type == 1 and oi.order_item # percent coupon
          list_of_items += "<tr><td>#{oi.tax_profile.name}</td><td>#{name} (#{ oi.category.name if oi.category })</td><td class='right'>#{number_to_percentage oi.price}</td><td class='center'>#{oi.quantity}</td><td class='right'>#{number_to_currency item_total}</td></tr>"
        elsif oi.behavior == 'coupon' and oi.item.coupon_type == 3 and oi.order_item
          list_of_items += "<tr><td>#{oi.tax_profile.name}</td><td>#{name}</td></tr>"
        else
          list_of_items += "<tr><td>#{oi.tax_profile.name}</td><td>#{name} (#{ oi.category.name if oi.category })</td><td class='right'>#{number_to_currency item_price}</td><td class='center'>#{oi.quantity}</td><td class='right'>#{number_to_currency item_total}</td></tr>"
        end

        if oi.discount_applied
          discount_price = - oi.discount_amount # ( oi.item.base_price * oi.quantity - oi.total ) / oi.quantity
          discount_total = discount_price * oi.quantity
          if oi.refunded then
            refund_subtotal -= discount_total
            discount_price = 0
            discount_total = 0
          end
          list_of_items += "<tr><td>#{oi.tax_profile.name}</td><td>Preisnachlass</td><td class='right'>#{ number_to_currency discount_price }</td><td class='center'>#{oi.quantity}</td><td class='right'>#{number_to_currency discount_total}</td></tr>"
          discount_subtotal += discount_total
        end

        if oi.rebate and oi.rebate > 0
          rebate_price = - ( oi.price * oi.rebate / 100.0)
          rebate_total = rebate_price * oi.quantity
          if oi.refunded then
            refund_subtotal -= rebate_total
            rebate_price = 0
            rebate_total = 0
          end
          list_of_items += "<tr><td>#{oi.tax_profile.name}</td><td>Rabatt</td><td class='center'>#{ number_to_currency rebate_price }</td><td class='center'>#{oi.quantity}</td><td>#{number_to_currency rebate_total}</td></tr>"
          rebate_subtotal += rebate_total
        end

        subtotal += item_total
      end
    puts subtotal, sum_taxes, discount_subtotal, rebate_subtotal, refund_subtotal, coupon_subtotal, list_of_items
    return subtotal, sum_taxes, discount_subtotal, rebate_subtotal, refund_subtotal, coupon_subtotal, list_of_items
  end
end
