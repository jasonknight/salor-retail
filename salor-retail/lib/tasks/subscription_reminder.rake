namespace :salor do
  task :subscription_reminder => [:environment] do
    Vendor.visible.each do |v|
      puts "\n\nRunning subscription reminder for vendor #{ v.name }. Please wait ..."
      recurrable_orders = v.recurrable_subscription_orders
      #recurrable_orders = Order.where(:subscription => true); # for testing
      if recurrable_orders.any?
        body = "<h1>Pending Recurrable Subscriptions</h1>\n"
        body += "<p><a href=\"#{ v.company.full_url }/orders?type=subscription\">Go here to generate invoices</a></p>\n"
        body += "<ul>"
        recurrable_orders.each do |o|
          body += "<li>"
          body += "Order ID #{ o.id }, #{ o.total_cents/100.0 } #{ o.currency }, on #{ o.subscription_next.strftime('%Y-%m-%d') }"
          if o.customer
            body += "\n<br />#{ o.customer.full_name }, #{ o.customer.company_name }"
          end
          body += "\n<ul>\n"
          o.order_items.visible.each do |oi|
            body += "\n<li>#{ oi.sku }, #{ oi.item.name }, #{ oi.total_cents / 100.0 } #{ oi.currency }</li>"
          end
          body += "</ul>\n"
          body += "</li>\n"
        end
        body += "</ul>\n"
        #puts body # for testing
        UserMailer.technician_message(v, "Recurrable Subscriptions Pending", body, nil).deliver
      end
    end
  end
end