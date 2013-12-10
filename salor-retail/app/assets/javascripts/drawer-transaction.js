sr.fn.drawer.showTransactionPopup = function() {
  $('#cash_drop').show();
  $("#transaction_type").val('');
  focusInput($("#cash_drop_amount"));
}

sr.fn.drawer.hideTransactionPopup = function() {
  $('#cash_drop').hide();
  $('.cash-drop-amount').removeClass('error-input');
  $('.cash-drop-amount').val('');
  focusInput($('#main_sku_field'));
}

sr.fn.drawer.saveTransaction = function() {
  if ($('.cash-drop-amount').val() == '') {
    $('.cash-drop-amount').addClass('error-input');
    $('.trans-button').removeClass('button-highlight');
    focusInput($('.cash-drop-amount'));
    return;
  }
  $('.cash-drop-amount').removeClass('error-input');
  if($("#transaction_type").val() == '') {
    $("#transButtonRow").addClass('error-input');
    alert("NoTypeSet");
    return;
  }
  $("transButtonRow").removeClass('error-input');
  $.ajax({
      type: 'POST',
      url: '/vendors/new_drawer_transaction',
      data: $('#cash_drop_form').serialize(),
      dataType: 'script',
      success: function (data) {
        $('textarea#cash-drop-notes-id').val('');
        $('.dt-tag-button').removeClass("highlight");
        $('input#dt_tag').val('None');
        $('div.dt-tag-target').html(' Tag ');
        sr.fn.drawer.hideTransactionPopup();
      },
      error: function (data,status,errorThrown) {
      messagesHash['prompts'].push(errorThrown);
      displayMessages();
      }
  });
  focusInput($('#main_sku_field'));
}

sr.fn.drawer.update = function(string) {
  $('.pos-cash-register-amount').html(string);
  $('.eod-drawer-total').html(string);
  $('#header_drawer_amount').html(string);
}
