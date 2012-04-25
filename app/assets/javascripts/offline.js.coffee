window.OrderItems = null
# We want to take advantage of the event driven nature
# of js, so we use events and we use body as the pipeline
window.emit = (message,data) ->
  ev = jQuery.Event(message)
  ev.data
  $('body').trigger(ev)
# Event Handlers
window.onOrderItemsRefreshed = (event) ->
  window.OrderItems = event.data
# Events
$('body').bind 'OrderItemsRefreshed', 
# The call that starts it all
window.refreshOrderItems = ->
  $.ajax
    type: 'get'
    url: '/order_items/index?format=json'
    success: (data) ->
      emit('OrderItemsRefreshed',data)
$ ->
  refreshOrderItems()
