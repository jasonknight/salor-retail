var sendingOrder = false;
var orderCompleteDisplayed = false;
var sendqueue = [];

function enablePrintReceiptButton() {
  if (sendqueue.length == 0 ) {
     $('#print_receipt_button').css('background-color', '#ed8b00');
  }
}

function disablePrintReceiptButton() {
  $('#print_receipt_button').css('background-color', '#999999');
}

function complete_order_show() {
  if (sendqueue.length > 0) {
    return;
  }
  ajax_log({log_action:'complete_order_show', order_id:Order.id});
  
  sendingOrder = false;
  $(".payment-amount").remove();
  $(".complete-order-total").html($('#pos_order_total').html());
  $("#complete_order_change").html('');
  $("#recommendation").html('');
  $('#complete_order').show();  
  set_invoice_button();

  orderCompleteDisplayed = true;

  $("#add_payment_method_button").show();
  $("#payment_methods").show();
  $("#payment_methods").html("");
  add_payment_method();
  $("#payment_amount_0").val(toDelimited(Order.total));
  $("#payment_amount_0").select();
  display_change('function complete_order_show');
  show_denominations();
  allow_complete_order(true);
  $('body').triggerHandler({type: "CompleteOrderShow"});
}

function set_invoice_button() {
  $('.a4-print-button').remove(); 
  var a4print = $("<div class='a4-print-button'><img src='/images/icons/a4print.svg' height='32' /></div>");
  var left = $('#complete_order').position().left;
  var width = $('#complete_order').width();
  var cpos = {x: width + left + 21, y:$('#complete_order').position().top + $('#complete_order').height() - 40 }; //because the first div needs to be on top
  a4print.css({width: '125px',position: 'absolute',top: cpos.y, left: cpos.x});
  relevant_order_id = Order.id;
  a4print.click(function () {
    window.location = '/orders/' + relevant_order_id + '/print';      
  });
  $("body").append(a4print);
}

function complete_order_hide() {
  stop_drawer_observer();
  $("#payment_methods").html("");
  $(".payment-amount").attr("disabled", true);
  $('#complete_order').hide();
  $('.a4-print-button').remove();
  $('.pieces-button ').remove();
  $('body').triggerHandler({type: "CompleteOrderHide"});
  ajax_log({log_action:'complete_order_hide', order_id:Order.id});
  if ( useMimo() ) {
    Salor.mimoRefresh(location.origin + "/vendors/" + Vendor.id + "/display_logo", 800, 480);
  }
  if ( parseInt( Order.id ) % 20 == 0) { 
    // reload the page every 20 orders to trigger garbage collection
    window.location = '/orders/new'; 
  }
}

function complete_order_send(print) {
  if (sendingOrder) return;
  if (Order.order_items_length == 0) { complete_order_hide(); return;}
  sendingOrder = true;
  allow_complete_order(false);
  if (Register.require_password) {
    // process after password entry
    show_password_dialog(print);
    return
  } else {
    // process immediately
    complete_order_process(print);
  }  
}

// this function handles all the magic regarding printing, drawer opening, drawer observing, pole display update and mimo screen update. detects usage of salor-bin too.
function complete_order_process(print,change_user_id) {
  var drawer_opened = conditionally_open_drawer();
  var order_id = Order.id;
  var current_payment_method_items = paymentMethodItems();
  $.ajax({
    url: "/orders/complete",
    type: 'POST',
    data: {
      order_id: Order.id,
      change_user_id: change_user_id,
      change: toFloat($('#complete_order_change').html()),
      print: print,
      payment_method_items: current_payment_method_items
    },
    complete: function(data, status) {
      ajax_log({log_action:'get:complete_order_ajax:callback', order_id:Order.id, require_password: false});
      if (print == true) { 
        print_order(order_id, function() {
          // observe after print has finished
          if (drawer_opened == true) observe_drawer();
        });
      } else {
        // observe immediately
        if (drawer_opened == true) observe_drawer();
      }
      sendingOrder = false;
      updateCustomerDisplay(order_id, false, true);
    },
    error: function(jqXHR, textStatus, errorThrown) {
      messagesHash['prompts'].push(errorThrown);
      displayMessages();
    }
  });
}

function allow_complete_order(userRequest) {
  var allowedBySystem = $('#pos-table-left-column-items').children().length > 0 || Order.is_proforma; // sine qua non condition of the system that the user cannot override.
  
  if (allowedBySystem && userRequest) {
    $("#confirm_complete_order_button").removeClass("button-inactive");
    $("#confirm_complete_order_button").off('click');
    $("#confirm_complete_order_button").on('click', function() {complete_order_send(true)});
    $("#confirm_complete_order_noprint_button").removeClass("button-inactive");
    $("#confirm_complete_order_noprint_button").off('click');
    $("#confirm_complete_order_noprint_button").on('click', function() {complete_order_send(false)});
  } else {
    
    $("#confirm_complete_order_button").addClass("button-inactive");
    $("#confirm_complete_order_button").off('click');
    $("#confirm_complete_order_noprint_button").addClass("button-inactive")
    $("#confirm_complete_order_noprint_button").off('click');
  }
}


function show_password_dialog(print) {
  var el = $("#simple_input_dialog").dialog({
    modal: false,
    buttons: {
      "Cancel": function() {
        $("#simple_input_dialog").dialog( "close" );
      },
      "Complete": function () {
        var bValid = true;
        $('#dialog_input').removeClass("ui-state-error");
        updateTips("");
        bValid = bValid && checkLength($('#dialog_input'),"password",3,255);
        if (bValid) {
          updateTips("Verifying user...");            
          $.post(
              "/users/verify",
              { password: $('#dialog_input').val() }, 
              function (data, status) {
                if (data == "NO") {
                  ajax_log({log_action:'password attempt failed!', order_id:Order.id, require_password: true});
                  updateTips("Wrong Password");
                } else {
                  updateTips("Correct, sending...");
                  var change_user_id = data.id;
                  complete_order_process(print,change_user_id);
                  updateTips("");
                  $("#simple_input_dialog").dialog( "close" );
                }
              } // end complete
          ); // end post
          
        } // end if bValid
      } // end Complete
    } // end Buttons
  }); // end dialog
  
  setTimeout(function () {
    $('#dialog_input').val("");
    $(".ui-dialog * button > span:contains('Complete')").text(i18n.menu.ok);
    $(".ui-dialog * button > span:contains('Cancel')").text(i18n.menu.cancel);
    $('#dialog_input').unbind('keyup');
    $('#dialog_input').keyup(function (event) {
      if (event.which == 13) {
        ajax_log({log_action:'Keyup enter on password dlg', order_id:Order.id});
        $(".ui-dialog * button:contains('"+i18n.menu.ok+"')").trigger("click");
      }
    });
    focusInput($('#dialog_input'));
    var ttl = el.parent().find('.ui-dialog-title');
    ttl.html(i18n.activerecord.attributes.require_password); 
    ttl = el.parent().find('.input_label');
    ttl.html(i18n.activerecord.attributes.password);
  },20);
}
