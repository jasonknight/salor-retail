function validate_order_totals() {
  var item_total = 0.0;
  $('.pos-item-total').each(function () {
    var total = toFloat($(this).html()); 
    if ($(this).hasClass('pos-highlight') && total > 0){
      item_total = item_total - total;
      $(this).html(toCurrency(total * -1));
    } else {
      item_total = item_total + total;
    }
  }); 
  if (!toCurrency(item_total) == $('.pos-order-total').html()) {
    notify_user(i18n.headings.order_validation, 
                i18n.system.errors.order_totals_validation_failed, function () {
                  window.location = "/orders/new";
                });
  }
}