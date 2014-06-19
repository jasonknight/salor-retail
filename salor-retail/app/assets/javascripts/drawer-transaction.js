sr.fn.drawer.showTransactionPopup = function() {
  $('#cash_drop').show();
  $("#transaction_type").val('');
  sr.fn.focus.set($("#cash_drop_amount"));
}

sr.fn.drawer.hideTransactionPopup = function() {
  $('#cash_drop').hide();
  $('.cash-drop-amount').removeClass('error-input');
  $('.cash-drop-amount').val('');
  sr.fn.focus.set($('#main_sku_field'));
}

sr.fn.drawer.saveTransaction = function() {
  if ($('.cash-drop-amount').val() == '') {
    $('.cash-drop-amount').addClass('error-input');
    $('.trans-button').removeClass('button-highlight');
    sr.fn.focus.set($('.cash-drop-amount'));
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
      },
      error: function (data,status,errorThrown) {
        sr.data.messages.prompts.push("Error during request: vendors new_drawer_transaction");
        sr.fn.messages.displayMessages();
      }
  });
  sr.fn.drawer.hideTransactionPopup();
  sr.fn.focus.set($('#main_sku_field'));
}

sr.fn.drawer.update = function(string) {
  $('.pos-cash-register-amount').html(string);
  $('.eod-drawer-total').html(string);
  $('#header_drawer_amount').html(string);
}

sr.fn.drawer.makeTagButtons = function(btn) {
  if (btn.hasClass("btn-done")) {
    return;
  }
  btn.mousedown(function (event) {
    $('.dt-tag-button').removeClass("highlight");
    $(this).addClass("highlight");
    if ($(this).attr('value') == 'None'){
      $('#dt_tag').val($(this).attr('value'));
      $('.dt-tag-target').html(i18n.activerecord.models.transaction_tag.one);
    } else {
      $('#dt_tag').val($(this).attr('value'));
      $('.dt-tag-target').html($(this).html());
    }
    $('.dt-tags').hide();
   });
  btn.addClass("button-done");
}