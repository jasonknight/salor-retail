$(document).ready(function(){
  $('#header_drawer_amount').html(toCurrency(Drawer.amount));
});

function show_cash_drop() {
  $('#cash_drop').show();
  $("#transaction_type").val('');
  focusInput($("#cash_drop_amount"));
}

function hide_cash_drop() {
  $('#cash_drop').hide();
  $('.cash-drop-amount').removeClass('error-input');
  $('.cash-drop-amount').val('');
  focusInput($('#main_sku_field'));
}

function cash_drop_save() {
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
        hide_cash_drop();
      },
      error: function (data,status,err) {
        alert(err);
      }
  });
  focusInput($('#main_sku_field'));
}



function updateDrawer(amount) {
  $('.pos-cash-register-amount').html(toCurrency(amount));
  $('.eod-drawer-total').html(toCurrency(amount));
  $('#header_drawer_amount').html(toCurrency(amount));
}
