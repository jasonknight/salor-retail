function print_order(id) {
   print_url(Register.thermal_printer,'/orders/print_receipt', '&order_id=' + id,'/orders/print_confirmed?order_id=' + id);
}

function print_url(printer_path,url,params,confirmation_url) {
  c_url = typeof(confirmation_url) !== 'undefined' ? Conf.url + confirmation_url : '';
  param_string = '?user_id=' + User.id + '&user_type=' + User.type + '&cash_register_id=' + Register.id + params;
  if (typeof SalorPrinter != 'undefined' && Register.salor_printer == true) {
    Salor.stopDrawerObserver(Register.cash_drawer_path);
    SalorPrinter.printURL(printer_path, Conf.url + url + param_string, c_url);
  } else {
    $.get(url + param_string);
  }
}

function playSound(file) {
  if (typeof Salor != 'undefined') {
    Salor.playSound(file);
  }
}
