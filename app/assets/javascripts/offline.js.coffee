# README FIRST PLEASE
# Okay, the general idea that I am working from here is similar to what you have in Qt or what not,
# Basically, we have some custom events, when something happens, we trigger and event, and then a
# defined even handler takes it and does whatever needs to be done
# Events:
#   OrderItemsRefreshed: Triggered when we get new JSON from the server.
window.OrderItems = null
# We want to take advantage of the event driven nature
# of js, so we use events and we use body as the pipeline
# we use the emit method, heredefined, to bubble up events
window.emit = (message,data) ->
  $('body').triggerHandler
    type: message,
    contents: data
# Event Handlers
window.onOrderItemsRefreshed = (event) ->
  window.OrderItems = event.contents
# Events
$('body').on('OrderItemsRefreshed', onOrderItemsRefreshed)
# The call that starts it all
window.refreshOrderItems = ->
  $.ajax
    type: 'get'
    url: '/order_items/index?format=json'
    success: (data) ->
      emit('OrderItemsRefreshed',data)
$ ->
