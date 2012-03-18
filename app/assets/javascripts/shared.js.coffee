$ ->
  if typeof(Salor) != 'undefined'
    Salor.stopDrawerObserver()

window.showButtonCategoryContainer = (id) ->
  $('.button-category-container').hide()
  $('#' + id).show()

window.quick_open_drawer = () ->
  if Register.cash_drawer_path != ''
    if typeof Salor != 'undefined'
      Salor.stopDrawerObserver(Register.cash_drawer_path)
      Salor.newOpenCashDrawer(Register.cash_drawer_path)
    else
      $.get('/vendors/open_cash_drawer')
