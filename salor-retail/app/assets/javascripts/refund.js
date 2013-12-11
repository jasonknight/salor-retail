sr.fn.refund.go = function(id) {
  refund_payment_method_id = $('#refund_payment_method').val();
  window.location = '/orders/refund_item?id=' + id + '&pm=' + refund_payment_method_id;
  if (sr.data.resources.payment_method_object[refund_payment_method_id].cash == true) {
    sr.fn.salor_bin.quickOpenDrawer()
  }
}