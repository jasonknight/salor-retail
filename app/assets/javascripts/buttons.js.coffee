$ ->
  $("#button_color").modcoder_excolor()

window.makeSortable = (id) ->
  $('#' + id).sortable
    dropOnEmpty: false
    cursor: 'crosshair'
    items: 'div.item-button'
    opacity: 0.4
    scroll: true
    update: () ->
      $.ajax
        type: 'post'
        data: $('#' + id).sortable('serialize')
        dataType: 'script'
        url: '/buttons/position'
