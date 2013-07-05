//=require ordersjs

window.refund_item = (id) ->
  refund_payment_method = $('#refund_payment_method').val()
  window.location = '/orders/refund_item?id=' + id + '&pm=' + refund_payment_method
  if refund_payment_method == 'InCash'
    # TODO: needs cash detection
    quick_open_drawer()