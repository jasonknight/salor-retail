function onCashDrawerClose() {
  complete_order_hide();
}

function print_order(id,callback) {
   print_url(Register.thermal_printer,'/orders/print_receipt', '&order_id=' + id,'/orders/print_confirmed?order_id=' + id,callback);
}

function print_url(printer_path,url,params,confirmation_url, callback) {
  c_url = typeof(confirmation_url) !== 'undefined' ? Conf.url + confirmation_url : '';
  param_string = '?user_id=' + User.id + '&user_type=' + User.type + '&cash_register_id=' + Register.id + params;
  if (params.indexOf('download=true') != -1) {
    window.location = url + param_string;
  } else if (typeof Salor != 'undefined' && Register.salor_printer == true) {
    Salor.stopDrawerObserver(Register.cash_drawer_path);
    Salor.printURL(printer_path, Conf.url + url + param_string, c_url);
    if (typeof callback == "function") {
      callback.call();
    }
  } else {
    $.get(url + param_string,callback);
  }
}

function playSound(file) {
  if (typeof Salor != 'undefined') {
    Salor.playSound(file);
  }
}

function useMimo() {
  return (isSalor() && (Register.pole_display == "" || !Register.pole_display));
}

function isSalor() {
  return (typeof(Salor) != 'undefined' );
}
