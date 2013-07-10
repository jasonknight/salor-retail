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

    $("#main_sku_field").attr("disabled", false);
    focusInput($("#main_sku_field"));
    $("#main_sku_field").keyup(function(e) {
      if (e.keyCode == 13) {
        add_item($("#main_sku_field").val(), '');
      }
    })
    
      setInterval(function () {
      if (
        !$('#cash_drop').is(":visible") && 
        !$('#complete_order').is(":visible") && 
        !$('#inplaceedit-div').is(":visible") && 
        !$('#search').is(":visible") &&
        !$('.void-order').is(":visible") &&
        !$('.ui-keyboard').is(":visible") && 
        !$('.salor-dialog').is(":visible")) {
      focusInput($("#main_sku_field"));
    } 
  }, 2000);