//= require jquery.keyboard
$ ->
  $('.keyboardable').each -> 
    make_keyboardable($(this))
  
  $('.keyboardable-int').each ->
    make_keyboardable($(this))
  $('.list-view tr:even').addClass('even')
  $('.list-view tr:last').removeClass('even')
  $('tr.no-stripe').removeClass('even');