function checkFocusInput() {
  if (focuseKeyboardInput) {
    focusInput($('#keyboard_input'));
    focuseKeyboardInput = false;
  }
}

function focusInput(inp) {
  $('.salor-focused').removeClass('salor-focused');
  inp.addClass('salor-focused');
  inp.focus();
  inp.select();
}
