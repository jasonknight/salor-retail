//= require jquery.keyboard
$ ->
  $('.keyboardable').each -> 
    make_keyboardable($(this))
  
  $('.keyboardable-int').each ->
    make_keyboardable($(this))
