sr.fn.salor_bin.is = function() {
  return (typeof(Salor) != "undefined" );
}

sr.fn.salor_bin.usePole = function() {
  return sr.fn.salor_bin.is() && sr.data.session.cash_register.customerscreen_mode == "pole";
}

sr.fn.salor_bin.useMimo = function() {
  return sr.fn.salor_bin.is() && sr.data.session.cash_register.customerscreen_mode == "mimo";
}

sr.fn.salor_bin.stopDrawerObserver = function() {
  if ( sr.fn.salor_bin.is() && sr.data.session.cash_register.thermal_printer != "") {
    Salor.stopDrawerObserver(sr.data.session.cash_register.thermal_printer);
  }
}


// always stops the drawer observer, then opens the drawer immediately and detects usage of salor-bin
sr.fn.salor_bin.quickOpenDrawer = function() {
  sr.fn.salor_bin.stopDrawerObserver()
  if ( sr.data.session.cash_register.thermal_printer != '') {
    if (sr.fn.salor_bin.is()) {
      if ( sr.data.session.cash_register.salor_printer == true ) {
        Salor.newOpenCashDrawer(sr.data.session.cash_register.thermal_printer);
      } else {
        $.get('/vendors/open_cash_drawer');
      }
    } else {
      $.get('/vendors/open_cash_drawer');
    }
  }
}

// this function returns true or false, which tells other functions if the cash drawer should be opened. for example, for a credit card transaction no cash drawer is needed.
sr.fn.salor_bin.shouldOpenDrawer = function() {
  var contains_cash_payment_method_item = false;
  var current_payment_method_items = sr.fn.payment.getItems();
  $.each(current_payment_method_items, function(k,v) {
    if (v.cash == true) {
      contains_cash_payment_method_item = true;
      return false;
    }
  });
  var open_drawer = contains_cash_payment_method_item || sr.data.session.cash_register.always_open_drawer == true;
  return open_drawer;
}

// opens the drawer only if customer has given cash or if the register configuration tells to open it always. no drawer observation is started at this point, since it would block subsequent printing.
sr.fn.salor_bin.maybeOpenDrawer = function() {
  //console.log("sr.fn.salor_bin.maybeOpenDrawer");
  if ( sr.fn.salor_bin.shouldOpenDrawer() == true ) sr.fn.salor_bin.quickOpenDrawer();
}

sr.fn.salor_bin.maybeObserveDrawer = function(delay) {
  //console.log("sr.fn.salor_bin.maybeObserveDrawer");
  if ( sr.fn.salor_bin.shouldOpenDrawer() == true ) sr.fn.salor_bin.observeDrawer(delay);
}

sr.fn.salor_bin.printOrder = function(id, callback) {
   sr.fn.salor_bin.printUrl(sr.data.session.cash_register.thermal_printer, '/orders/print_receipt', '&order_id=' + id, callback);
}

sr.fn.salor_bin.printUrl = function(printer_path, url, param_string, callback) {
  c_url = typeof(confirmation_url) !== 'undefined' ? location.origin + confirmation_url : '';
  param_string = "?printurl=1&" + param_string;
  if (param_string.indexOf('download=true') != -1) {
    window.location = url + param_string;
  } else if (sr.fn.salor_bin.is() && sr.data.session.cash_register.salor_printer == true) {
    sr.fn.salor_bin.stopDrawerObserver();
    Salor.printURL(printer_path, location.origin + url + param_string, callback);
  } else {
    $.get(url + param_string, function() {
      eval(callback);
    });
  }
}

sr.fn.salor_bin.playSound = function(file) {
  if (sr.fn.salor_bin.is()) {
    //console.log('playsound', file);
    Salor.playSound(file);
  }
}



sr.fn.salor_bin.updateCustomerDisplay = function(order_id, item, show_change) {
  if ( sr.fn.salor_bin.useMimo() ) {
    console.log(location.origin + "/orders/" + order_id + "/customer_display")
    Salor.mimoRefresh(location.origin + "/orders/" + order_id + "/customer_display", 800, 480);
  }
  
  if ( sr.fn.salor_bin.usePole() ) {
    if (item == false) {
      // after complete order
      given = parseFloat(sr.fn.payment.getTotal());
      given = sprintf(" %s %6.2f", Region.number.currency.format.unit, given);
      change = parseFloat($('#complete_order_change').html().replace(',','.').substring(1));
      change = sprintf(" %s %6.2f", Region.number.currency.format.unit, change);
      blurb_line1 = (i18n.views.given + '       ').substring(0,9);
      blurb_line2 = (i18n.views.change + '       ').substring(0,9);
      Salor.poleDancer(sr.data.session.cash_register.pole_display, blurb_line1 + given + blurb_line2 + change );
    } else {
      // after item add
      output = sr.fn.salor_bin.formatPole(item['name'], item['price'], item['quantity'], item['weight_metric'], item['subtotal']); 
      Salor.poleDancer(sr.data.session.cash_register.pole_display, output );
    }
  }
}

sr.fn.salor_bin.formatPole = function(name, price, quantity, weight_metric, total) {
  if (weight_metric == null) { weight_metric = '' };
  pole_name     = (name.substring(0,14) + '                ').substring(0,14);
  pole_price    = sprintf("%6.2f",price);
  pole_quantity = (quantity + ' ' + weight_metric + '                            ').substring(0,10);
  pole_total    = i18n.number.currency.format.friendly_unit + sprintf(" %6.2f",total);
  return pole_name + pole_price + pole_quantity + pole_total;
}

// this is a callback used mainly by print_url
sr.fn.salor_bin.observeDrawer = function(delay) {
  if (sr.fn.salor_bin.is()) {
    setTimeout(function() {
      Salor.startDrawerObserver(sr.data.session.cash_register.thermal_printer);
    },
    delay);
  }
}

sr.fn.salor_bin.weighItem = function(id) {
  if ( ! sr.fn.salor_bin.is() ) {
    sr.data.messages.prompts.push("Weighing is only supported with our thin client salor-bin.");
    sr.fn.messages.displayMessages();
    return
  }
  
  var weight = "";
  
  if (typeof sr.data.session.cash_register.scale != 'undefined' && sr.data.session.cash_register.scale != '') {
     weight = Salor.weigh(sr.data.session.cash_register.scale, 0);
     //weight = new Date().getSeconds() + ".123"; // test without scale
    
  } else {
    sr.data.messages.prompts.push("No scale configured. Please add a scale path to the CashRegister settings.");
    sr.fn.messages.displayMessages();
    weight = "0.000";
  }

  var weight_formatted = weight.replace('.', Region.number.currency.format.separator);
  
  var req = '/vendors/edit_field_on_child?id=' +
  id +
  '&klass=OrderItem' +
  '&field=quantity'+
  '&value=' + weight_formatted;
  
  get(req, 'sr.fn.salor_bin.weighItem()');
  
  if (parseFloat(weight) == 0 || isNaN(parseFloat(weight))) {
    sr.fn.salor_bin.playSound('medium_warning');
  }
  return parseFloat(weight);
}

function weigh_last_item() {
  var top_item = $(".pos-table-left-column-items").children()[0]
  var id = $(top_item).attr('model_id');
  sr.fn.salor_bin.weighItem(id);
}

sr.fn.salor_bin.showPrintDialog = function() {
  if (sr.fn.salor_bin.is()) {
    Salor.printPage();
  } else {
    print();
  }
}