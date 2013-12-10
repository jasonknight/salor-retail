sr.fn.refund.go = function(id) {
  refund_payment_method_id = $('#refund_payment_method').val();
  window.location = '/orders/refund_item?id=' + id + '&pm=' + refund_payment_method_id;
  if (PaymentMethodObjects[refund_payment_method_id].cash == true) {
    quick_open_drawer()
  }
}