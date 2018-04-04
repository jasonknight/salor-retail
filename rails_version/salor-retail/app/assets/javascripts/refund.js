sr.fn.refund.go = function(id) {
  var refund_payment_method_id = $('#refund_payment_method').val();
  window.location = '/orders/refund_item?id=' + id + '&pm=' + refund_payment_method_id;
  if (sr.data.resources.payment_method_object["pmid" + refund_payment_method_id].cash == true) {
    sr.fn.salor_bin.quickOpenDrawer();
  }
}