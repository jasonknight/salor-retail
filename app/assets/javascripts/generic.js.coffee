//=require genericjs

$ ->
  if typeof(Salor) != 'undefined'
    Salor.stopDrawerObserver()
    $('#salorbinversion').html(Salor.version());

window.showButtonCategoryContainer = (id) ->
  $('.button-category-container').hide()
  $('#' + id).show()

window.showJsError = (err) ->
  txt="There was an error on this page _pos_js.\n\n"
  txt+="Error description: " + err.description + "\n\n"
  txt+="Error message: " + err.message + "\n\n"
  txt+="Error Line: " + err.line + "\n\n"
  txt+="Click OK to continue.\n\n"
  alert(txt)

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
