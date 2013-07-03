function checkFocusInput() {
  if (focuseKeyboardInput) {
    focusInput($('#main_sku_field'));
    focuseKeyboardInput = false;
  }
}

function focusInput(inp) {
  $('.salor-focused').removeClass('salor-focused');
  inp.addClass('salor-focused');
  inp.focus();
}