window.addSkuViaButton = (sku) ->
  $.ajax
    url: '/orders/add_item_ajax?no_inc=true&order_id='+$('.order-id').html()+'&sku=' + sku
    success: $('#buttons').hide()

window.refund_item = (id) ->
  refund_payment_method = $('#refund_payment_method').val()
  window.location = '/orders/refund_item?id=' + id + '&pm=' + 
  if refund_payment_method == 'InCash'
    quick_open_drawer()
