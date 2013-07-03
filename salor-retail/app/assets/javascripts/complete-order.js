function complete_order_show() {
  sendingOrder = false;
  $(".payment-amount").remove();
  complete_total = Order.total;
  if (isBuyOrder) complete_total *= -1;
  $(".complete-order-total").html($('#pos_order_total').html());
  $("#complete_order_change").html('');
  $("#recommendation").html('');
  //allow_complete_order(isBuyOrder); // need to get the total money tended > complete_total before active unless this isBuyOrder
  $('#complete_order').show();
  
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
  bindInplaceEnter(false);
  handleKeyboardEnter = false;
  orderCompleteDisplayed = true;

  setOnEnterKey(function(event) {
    if (event.keyCode == 13 && orderCompleteDisplayed) {
      ajax_log({log_action:'complete_order_show:setOnEnterKey', order_id:Order.id, value:event.keyCode});
      if (Register.no_print == true) {
          complete_order_send(false);
      } else {
          complete_order_send(true);
      }
      event.preventDefault();
    }
  });

  setOnEscKey(function() {
    complete_order_hide();
  });

  if (isBuyOrder) {
    $("#add_payment_method_button").hide();
    $("#payment_methods").hide();
  } else {
    $("#add_payment_method_button").show();
    $("#payment_methods").show();
  }
  $("#payment_methods").html("");
  add_payment_method();
  $("#payment_amount_0").val( complete_total );
  $("#payment_amount_0").select();
  display_change('function complete_order_show');
  show_denominations();
  $("#keyboard_input").attr("disabled", true);
  allow_payment_amount = true;
  $('body').triggerHandler({type: "CompleteOrderShow"});
}


function complete_order_hide() {
  if (typeof Salor != 'undefined') {
    if (Register.cash_drawer_path != "" ) {
      Salor.stopDrawerObserver();
    }
    if ( useMimo() ) {
    } else {
      Salor.poleDancer(Register.pole_display, Register.customer_screen_blurb);
    }
  }
  $("#payment_methods").html("");
  $(".payment-amount").attr("disabled", true);
  $('#complete_order').hide();
  bindInplaceEnter(true);
  handleKeyboardEnter = true;
  orderCompleteDisplayed = false;
  unsetOnEnterKey();
  unsetOnEscKey();
  $('.a4-print-button').remove();
  $('.pieces-button ').remove();
  $("#keyboard_input").attr("disabled", false);
  if (typeof bycard_hide != 'undefined') {
    bycard_hide();
  }
  focuseKeyboardInput = true;
  $('body').triggerHandler({type: "CompleteOrderHide"});
  ajax_log({log_action:'complete_order_hide', order_id:Order.id});
  if ( parseInt( Order.id ) % 20 == 0) { 
    window.location = '/orders/new'; 
  } // trigger intensified garbage collection regularly
  
}

function complete_order_send(print) {
  if (print === false) {
    print = 'false';
  } else {
    print = 'true';
  }
  if (sendingOrder) return;
  if (Order.order_items.length == 0) { complete_order_hide(); return;}
  allow_payment_amount = false;
  sendingOrder = true;
  allow_complete_order(false);
  displayChangeToCustomer();
  print_order_id = Order.id;
  // begin require password code
  if (Register.require_password) {
    _set("print_order",print,$("#simple_input_dialog"));
    _set("print_order_id",print_order_id,$("#simple_input_dialog"));
    var el = $("#simple_input_dialog").dialog({
      modal: true,
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
            jQuery.post("/users/verify",{password: $('#dialog_input').val()},function (data,textStatus,jqHXR) {
              if (data == "NO") {
                ajax_log({log_action:'password attempt failed!', order_id:Order.id, require_password: true});
                updateTips("Wrong Password");
              } else {
                if ( 
                      (serializePayments().indexOf('InCash') != -1) || 
                      Register.always_open_drawer == true
                   ) { quick_open_drawer(); }
                get('/orders/complete_order_ajax?user_id=' + data.id + '&order_id='+Order.id+'&ajax=true&change='+toFloat($('#complete_order_change').html())+'&print=' + print + '&' + decodeURIComponent(serializePayments()), 
                    filename, 
                    function() {
                          ajax_log({log_action:'get:complete_order_ajax:callback', order_id:Order.id, require_password: true});
                          if (_get("print_order",$("#simple_input_dialog")) == 'true') {
                            print_order(_get("print_order_id",$("#simple_input_dialog")), function () {
                              if ( (serializePayments().indexOf('InCash') != -1) || Register.always_open_drawer == true) {
                                if (Register.cash_drawer_path != "" && typeof(Salor) != 'undefined' ) {
                                  setTimeout("Salor.startDrawerObserver(Register.cash_drawer_path);",2000);
                                }
                              }
                            }); 
                          } else {
                              if ( (serializePayments().indexOf('InCash') != -1) || Register.always_open_drawer == true) {
                                if (Register.cash_drawer_path != "" && typeof(Salor) != 'undefined' ) {
                                  setTimeout("Salor.startDrawerObserver(Register.cash_drawer_path);",2000);
                                }
                              }
                          }
                          sendingOrder = false;
                          _set("print_order",'false',$("#simple_input_dialog"));
                          if ( useMimo() ) {
                            Salor.mimoRefresh(Conf.url + "/orders/" + print_order_id + "/customer_display?display_change=1",800,480);
                          }
                    }, /* end anon func*/
                    'get', 
                    null); // end get()
                 $("#simple_input_dialog").dialog( "close" );
              } // end else
            }).fail(function () {
              updateTips("Login to server failed due to server error, call tech support!");
            });

          } // end if bValid
        },
        
      }
    });
    
    setTimeout(function () {
      $('#dialog_input').val("");
      $(".ui-dialog * button > span:contains('Complete')").text(i18n.menu.ok);
      $(".ui-dialog * button > span:contains('Cancel')").text(i18n.menu.cancel);
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
    return; // we return from here so that we stop the sending of the order
  }
  /* end require password code */
  
  
  if ( (serializePayments().indexOf('InCash') != -1) || Register.always_open_drawer == true) { quick_open_drawer();}
  get('/orders/complete_order_ajax?order_id='+Order.id+'&ajax=true&change='+toFloat($('#complete_order_change').html())+'&print=' + print + '&' + decodeURIComponent(serializePayments()), 
      filename, 
      function() {
          ajax_log({log_action:'get:complete_order_ajax:callback', order_id:Order.id, require_password: false});
          if (print == 'true') { 
            print_order(print_order_id,function () {
              if ( (serializePayments().indexOf('InCash') != -1) || Register.always_open_drawer == true) {
                if (Register.cash_drawer_path != "" && typeof(Salor) != 'undefined' ) {
                  setTimeout("Salor.startDrawerObserver(Register.cash_drawer_path);",2000);
                }
              }
            }); // end print_order 
          } else {
              if ( (serializePayments().indexOf('InCash') != -1) || Register.always_open_drawer == true) {
                if (Register.cash_drawer_path != "" && typeof(Salor) != 'undefined' ) {
                  setTimeout("Salor.startDrawerObserver(Register.cash_drawer_path);",2000);
                }
              }
          }
          sendingOrder = false;
          if (typeof(Salor) != 'undefined') {
            if ( useMimo() ) {
              Salor.mimoRefresh(Conf.url + "/orders/" + print_order_id + "/customer_display?display_change=1",800,480);
            }
          }
    }, 'get', function() {
    sendingOrder = false;
    //allow_complete_order();
    allow_payment_amount = true;
  });
}


function showCompleteOrderPopup() {
  var tmpl = getCompleteOrderTemplate();
  tmpl.dialog({
    autoOpen: true,
    height: $(window).height() * 0.8,
    width: $(window).width() * 0.8,
    modal: true,
    buttons: getCompleteOrderButtons(),
  });
  $("#payment_method_list").html('');
  completeOrderShowTotal(tmpl);
  completeOrderShowChange(tmpl);
  _set("payment_methods_used",[],getCompleteOrderTemplate());
}

function getCompleteOrderTemplate() {
  return $("#complete_order_popup");
}

function getCompleteOrderButtons() {
  return {
    "Cancel":           function () { $(this).dialog( "close" ); }, //end Cancel
    "Complete":         function () { compleOrder(false);       }, //end Complete
    "Print":            function () { compleOrder(true);        }, // end Print
  };
}

// function completeOrder(print) {
//   var bValid = true;
// }

function completeOrderShowTotal(tmpl) {
  var el = $('#complete_order_total');
  var w = 300;
  el.css({width: w});
  completeOrderUpdateTotal(Order.total);
}

function completeOrderShowChange(tmpl) {
  var el = $('#complete_order_change');
  var w = 300;
  el.css({width: w});
  completeOrderUpdateChange(0);
}

function completeOrderUpdateTotal(num) {
  var el = $("#complete_order_total");
  var _ttl = toCurrency(num);
  el.html(_ttl);
}

function completeOrderUpdateChange(num) {
  var el = $("#complete_order_change");
  var _ttl = toCurrency(num);
  el.html(_ttl);
}

function completeOrderRightCol() {
  return $("#complete_order_popup .content-table td.right");
}

function completeOrderAddPaymentMethod() {
  var pm = {name: "notset",internal_type: "notset"};
  var pm_options = [];
  var selected = false;
  for (var i = 0; i < PaymentMethodObjects.length; i++) {
    if (_get("payment_methods_used",getCompleteOrderTemplate()).indexOf(PaymentMethodObjects[i].internal_type) == -1 && selected == false) {
      pm = PaymentMethodObjects[i];
      pm_options.push( _.template('<option value="{{=internal_type}}" selected="true">{{= name }}</option>')(PaymentMethodObjects[i]));
      selected = true;
      continue;
    }
    pm_options.push(_.template('<option value="{{=internal_type}}">{{= name }}</option>')(PaymentMethodObjects[i]));
  }
  var tmpl = _.template($("#payment_method_template").html())({pm: pm, i: 0, options: pm_options.join("\n")});
  var row = $(tmpl);
  $("#payment_method_list").append(row);
  var select = row.find("select");
  make_select_widget("",select);
  completeOrderUpdatePaymentMethodsUsed();
  focusInput(row.find("input"));
}

function completeOrderUpdatePaymentMethodsUsed() {
  var pms_used = [];//_get("payment_methods_used",getCompleteOrderTemplate());
  $(".payment-method-select").each(function () {
    pms_used.push($(this).val());
  });
  _set("payment_methods_used",pms_used,getCompleteOrderTemplate());
}

function allow_complete_order(isAllowed) {
  if (isAllowed == null) isAllowed = true;
  if (typeof(isAllowed) == 'undefined') isAllowed = true;
  if (isAllowed && $('#pos-table-left-column-items').children().length > 0 || Order.is_proforma) {
    $("#confirm_complete_order_button").removeClass("button-inactive");
    $("#confirm_complete_order_button").unbind('click');
    $("#confirm_complete_order_button").click(function(){complete_order_send(true)});
    $("#confirm_complete_order_noprint_button").removeClass("button-inactive");
    $("#confirm_complete_order_noprint_button").unbind('click');
    $("#confirm_complete_order_noprint_button").click(function(){complete_order_send(false)});
    $("#cancel_complete_order_button").html(i18n_menu_cancel);
  } else {
    $("#confirm_complete_order_button").addClass("button-inactive");
    $("#confirm_complete_order_button").unbind('click');
    $("#confirm_complete_order_noprint_button").addClass("button-inactive")
    $("#confirm_complete_order_noprint_button").unbind('click');
    $("#cancel_complete_order_button").html(i18n_menu_done);
  }
}

