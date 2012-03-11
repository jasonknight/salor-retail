//=require genericjs

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
