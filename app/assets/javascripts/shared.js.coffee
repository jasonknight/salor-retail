window.showButtonCategoryContainer = (id) ->
  $('.button-category-container').hide()
  $('#' + id).show()

window.quick_open_drawer = () ->
  if typeof Salor != 'undefined'
    Salor.newOpenCashDrawer(Register.cash_drawer_path)
  else
    $.get('/vendors/open_cash_drawer')
