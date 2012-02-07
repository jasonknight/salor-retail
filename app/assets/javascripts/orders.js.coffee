window.addSkuViaButton = (sku) ->
  $.ajax
    url: '/orders/add_item_ajax?no_inc=true&order_id='+$('.order-id').html()+'&sku=' + sku
    success: $('#buttons').hide()
