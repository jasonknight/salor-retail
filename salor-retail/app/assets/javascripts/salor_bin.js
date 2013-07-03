function isSalorBin() {
  return (typeof(Salor) != 'undefined' );
}

function usePole() {
  return (isSalorBin() && typeof Register.pole_display != "undefined" && Register.pole_display.length > 1);
}

function useMimo() {
  return isSalorBin() && !usePole();
}

function onCashDrawerClose() {
  complete_order_hide();
}


// always stops the drawer observer, then opens the drawer immediately and detects usage of salor-bin
function quick_open_drawer() {
  if ( Register.cash_drawer_path != '') {
    if (isSalorBin()) {
      Salor.stopDrawerObserver(Register.cash_drawer_path);
      if ( Register.salor_printer == true ) {
        Salor.newOpenCashDrawer(Register.cash_drawer_path);
      } else {
        $.get('/vendors/open_cash_drawer');
      }
    } else {
      $.get('/vendors/open_cash_drawer');
    }
  }
}


// opens the drawer only if customer has given cash or if the register configuration tells to open it always. no drawer observation is started at this point, since it would block subsequent printing.
function conditionally_open_drawer() {
  var contains_cash_payment_method_item = false;
  $.each(paymentMethodItems(), function(k,v) {
    if (v.cash == true) {
      contains_cash_payment_method_item = true;
      return false;
    }
  });
  var open_drawer = contains_cash_payment_method_item || Register.always_open_drawer == true;
  if ( open_drawer ) {
    quick_open_drawer();
  }
  return open_drawer;
}


function print_order(id, callback) {
   print_url(Register.thermal_printer, '/orders/print_receipt', '&order_id=' + id,'/orders/print_confirmed?order_id=' + id, callback);
}

function print_url(printer_path, url, params, confirmation_url, callback) {
  c_url = typeof(confirmation_url) !== 'undefined' ? Conf.url + confirmation_url : '';
  param_string = '?user_id=' + User.id + '&user_type=' + User.type + '&cash_register_id=' + Register.id + params;
  if (params.indexOf('download=true') != -1) {
    window.location = url + param_string;
  } else if (isSalorBin() && Register.salor_printer == true) {
    Salor.stopDrawerObserver(Register.cash_drawer_path);
    Salor.printURL(printer_path, Conf.url + url + param_string, c_url);
    if (typeof callback == "function") {
      callback.call();
    }
  } else {
    $.get(url + param_string, callback);
  }
}

function playSound(file) {
  if (isSalorBin()) {
    Salor.playSound(file);
  }
}



function updateCustomerDisplay(order_id, item, show_change) {
  if ( useMimo() ) {
    var show_change_param = ""
    if (show_change) show_change_param = "?display_change=1";
    Salor.mimoRefresh(Conf.url + "/orders/" + order_id + "/customer_display" + show_change_param, 800, 480);
    
  }
  
  if ( usePole() ) {
    if (item == false) {
      // after complete order
      given = parseFloat(get_payment_total());
      given = sprintf(" %s %6.2f", i18nunit, given);
      change = parseFloat($('#complete_order_change').html().replace(',','.').substring(1));
      change = sprintf(" %s %6.2f", i18nunit, change);
      blurb_line1 = (i18n_money_given + '       ').substring(0,9);
      blurb_line2 = (i18n_money_change + '       ').substring(0,9);
      Salor.poleDancer(Register.pole_display, blurb_line1 + given + blurb_line2 + change );
    } else {
      // after item add
      output = format_pole(item['name'], item['price'], item['quantity'], item['weight_metric'], item['subtotal']); 
      Salor.poleDancer(Register.pole_display, output );
    }
  }
}

function format_pole(name, price, quantity, weight_metric, total) {
  if (weight_metric == null) { weight_metric = '' };
  pole_name     = (name.substring(0,14) + '                ').substring(0,14);
  pole_price    = sprintf("%6.2f",price);
  pole_quantity = (quantity + ' ' + weight_metric + '                            ').substring(0,10);
  pole_total    = i18n.number.currency.format.friendly_unit + sprintf(" %6.2f",total);
  return pole_name + pole_price + pole_quantity + pole_total;
}

// this is a callback for print_url. the timeout must be greater than the time that escper needs to open and close the device node, which is just a few milliseconds.
function observe_drawer() {
  if (isSalorBin()) {
    setTimeout(function() {
      Salor.startDrawerObserver(Register.cash_drawer_path);
    },
    1000);
  }
}