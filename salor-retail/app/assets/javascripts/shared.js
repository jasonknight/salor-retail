var IS_APPLE_DEVICE = navigator.userAgent.match(/iPhone|iPad|iPod/i) != null;
var IS_IPAD = navigator.userAgent.match(/iPad/i) != null;
var IS_IPOD = navigator.userAgent.match(/iPod/i) != null;
var IS_IPHONE = navigator.userAgent.match(/iPhone/i) != null;


var automatic_printing = false;
var debugmessages = [];
var _CTRL_DOWN = false;
var _key_codes = {tab: 9,shift: 16, ctrl: 17, alt: 18, f2: 113};
var _keys_down = {tab: false,shift: false, ctrl: false, alt: false, f2: false};

var oldPaymentMethod = "";
var allow_payment_amount = true;
var orderCompleteDisplayed = false;

var _called = 0;
var complete_total = 0;
var sendingOrder = false;

// documentready
$(function(){
  jQuery.ajaxSetup({
      'beforeSend': function(xhr) {
          //xhr.setRequestHeader("Accept", "text/javascript");
          xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
      }
  })

  $(window).keydown(function(e){
    for (var key in _key_codes) {
      if (e.keyCode == _key_codes[key]) {
        _keys_down[key] = true;
      }
    }
  });
  
  $(window).keyup(function(e){
    for (var key in _key_codes) {
      if (e.keyCode == _key_codes[key]) {
        _keys_down[key] = false;
      }
    }
  });
  
  $(".payment-method").live("change", function(){
    validatePaymentMethod($(this));
  });
  
  $(".currency").click(addCashAmount);
  
  $("#cancel_complete_order_button").click(complete_order_hide);
});

function payment_method_options() {
  var txt = '';
  for (var i=0; i<payment_internal_types.length; i++) {
    txt = txt + '<option value="' + payment_internal_types[i] + '">'+payment_external_types[i]+'</option>';
  }
  return txt;
}

function add_payment_method() {
  if ($(".payment-amount").size() >= payment_internal_types.length) return;
  var d = div();
  var numMethods = $(".payment-amount").size();
  d.addClass('payment-method');
  var amount = $('<input type="text" name="payment_methods[][amount]" id="' + "payment_amount_" + numMethods + '" class="payment-amount text-input keyboardable-int" value="" size="5" /> ');
  var opts = payment_method_options();
  var sel = $('<select name="payment_methods[][internal_type]" id="' + "payment_type_" + numMethods + '" class="payment-method">'+payment_method_options()+'</select>');
  sel.on('change', function(){
    checkAndDisplayChange();
    ajax_log({log_action:'select_payment_method', button_id:sel.attr('id'), value:sel.val(), order_id:Order.id});
  });

  $(sel)[0].selectedIndex = numMethods;
  $("#payment_methods").append(sel).append(amount);
  $('#payment_methods').append('<br />');
  oldSelectedIndex = null;
  validatePaymentMethod($(sel));
  amount.on("keyup",function (event) {
    checkAndDisplayChange("payment-amount.onKeyUp " + event.which + " " + _get("sel",$(this)).val());
  });
  make_select_widget($(sel).find("option:selected"),$(sel));
  make_keyboardable_with_options(amount, {
    visible: function () {
      var cls = $(sel).val() + '-amount';
      $(".ui-keyboard-preview").removeClass('payment-amount');
      if (IS_APPLE_DEVICE) {
        $(".ui-keyboard-preview").val("");
      }
      $("." + cls).select();
    },
    accepted: function () {
      display_change('keyboard '+sel.val());
    }
  });
  
  display_change('function add_payment_method');
  setTimeout(function () {
    focusInput(amount);
    amount.select();
  },100);
  _set("sel",sel,amount);
  ajax_log({log_action:'add_payment_method', order_id:Order.id, value:sel.val()});
}


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

function wholesaler_update() {
  var answer = confirm('Are you sure?')
  if (!answer) { return; }
  //TODO: needs a progress spinner and a real dialog in the dom since salor-bin can't display alerts
  window.location = '/shippers/update_wholesaler';
}

function show_denominations() {
    var center = {x: $('#complete_order').position().left - 135,y: $('#complete_order').position().top + 15};
    var doc = 99; // radius
    var cpos = {x: center.x, y: center.y }; //because the first div needs to be on top
    for (var i in i18n_pieces) {
      p = $('<div id="complete_piece_'+ i18n_pieces[i] + '">'+toCurrency(i18n_pieces[i])+'</div>');
      p.css({height: '35px',width: '125px',position: 'absolute',top: cpos.y, left: cpos.x});
      p.addClass("pieces-button shadow");
        cpos = {x: cpos.x, y: cpos.y + 54};
        p.attr('amount',i18n_pieces[i]);
        p.click(function () {
          var val = toFloat($(this).attr('amount'));
          $("#payment_amount_0").val( val );
          display_change('pieces-button ' + val);
          ajax_log({log_action:'pieces-button', value:val, order_id:Order.id});
        } );
        $('body').append(p);
    }
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



function addCashAmount() {
  if (complete_total == 0) return;
  var addAmount = toFloat($(this).val());
  var curAmount = toFloat($("#complete_in_cash").val());
  $("#complete_in_cash").val(curAmount + addAmount);
  display_change('function addCashAmount');
  focusInput($("#complete_in_cash"));
}

function initInput(type) {
  var input = $("#complete_in_" + type);
  if (isBuyOrder) {
    $(input).attr('disabled', true);
  } else {
    if ($(input).val() == "0") $(input).val('');
    $(input).attr('disabled', false);
 }
}

function blurInput(type) {
  var input = $("#complete_in_" + type);
  if ($(input).val() == "") $(input).val("0");
}

function displayAdvertising() {
  
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

function get_highest(num) {
  if (isNaN(num)) {
    num = 0;
  }
  if (num == 0) {
    return ['<%= t("views.forms.no_change") %>',0];
  }
  var highest_piece = i18n_pieces.length - 1;
  for (var i = i18n_pieces.length-1; i > 0; i--) {
    if (i18n_pieces[i] >= num) {
      highest_piece = i-1;
    } else {
      break;
    }
  }
  var times = Math.floor(num / i18n_pieces[highest_piece]);
  var display_line = times + ' x ' + toCurrency(i18n_pieces[highest_piece]);
  var remainder = roundNumber(num - (times * i18n_pieces[highest_piece]),2);
  return [display_line,remainder];
}


function recommend(num) {
  var parts = [];

  var ret = get_highest(num);
  parts.push(div_wrap(ret[0],'complete-recommendation-item'));
  cap = 20;
  x = 0;
  while (ret[1] > 0) {
    var ret = get_highest(ret[1]);
    parts.push(div_wrap(ret[0],'complete-recommendation-item'));
    x = x + 1;
    if (x > cap) {
      break;
    }
  }
  $('#recommendation').html(parts.join(' '));
}

function get_payment_total() {
  var paymentTotal = 0;
  $(".payment-amount:visible").each(
    function () {
      echo("Payment entry found, value is: " + $(this).val());
      var tval = toFloat($(this).val());
      paymentTotal += tval;
      echo("Payment entry converts to: " + tval);
    }
  );
  return paymentTotal;
}

function display_change(called_from) {
  echo("Displaying change calculation for Order #" + Order.id + " displayed total is " + $('#pos_order_total').html()); 
  if (sendingOrder) {
    echo("sendingOrder is true");
    return;
  }
  var paymentTotal = get_payment_total();
  echo("paymentTotal is " + paymentTotal);
  if (paymentTotal < 0) {
    paymentTotal = paymentTotal * -1;
  }
  var ototal = Order.total;
  if (ototal < 0) {
    ototal = ototal * -1;
  }
  var change = paymentTotal - ototal;
  change = Round(change,2);
  echo("Calculated change thus far is " + change);
  if (change < 0.0 && Order.total > 0) {
    //recommend(0);
    $('#complete_order_change').html(toCurrency(0));
    allow_complete_order(false);
  } else {
    if (Order.total < 0) {
      change = Order.total * -1;
    } 
    //recommend(change);
    $('#complete_order_change').html(toCurrency(change));
    echo('calling allow complete_order from display_change');
    allow_complete_order();
  }
  if(change > 0) { displayChangeToCustomer(); }
  ajax_log({log_action:'display_change', order_id:Order.id, paymentTotal:paymentTotal, ototal:ototal, change:change, called_from:called_from});
  return change;
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





function number_to_currency(num) {
  return i18nlocale + num;
}




function validatePaymentMethod(element) {
  var unusedPaymentTypes = payment_internal_types.slice(0);
  $.each($(".payment-method"), function(){
    if ($(element).attr("id") != $(this).attr("id")) {
      var index = unusedPaymentTypes.indexOf($(this).val());
      if (index > -1) unusedPaymentTypes[index] = ""; // need to keep all indexes in place
    }
  });
  if (unusedPaymentTypes.indexOf($(element).val()) == -1) {
    var setIndex;
    if (oldSelectedIndex === null) {
      // find first open iundex
      for (i=0; i<unusedPaymentTypes.length; i++) {
        if (unusedPaymentTypes[i]) {
          setIndex = i;
          i = unusedPaymentTypes.length;
        }
      }
      $(element).attr('selectedIndex');
    } else {
      setIndex = oldPaymentMethod;
    }
    $(element).attr('selectedIndex', setIndex);
  }
  var index = $(element).attr('id').split("_")[2];
  var pay_input = $("#payment_amount_" + index);

  // Since cardTotal is the remaining amount, and it's calculated automatically, the 
  // cardTotal calc will cycle between 0 and the remaining amount for every other
  // payment-method change! So, we fix it:
  var cardTotal = Math.round((complete_total - get_payment_total()) * 100);
  if (cardTotal <= 0) {
    cardTotal = pay_input.val();
  } else {
    cardTotal = parseInt(cardTotal) / 100;
    if (cardTotal + get_payment_total() > complete_total) {
      cardTotal = 0;
    }
  }
  if (cardTotal == '') {
    cardTotal = 0;
  }
  // Here we tag the input field, so that it is easily accessible with class access like ByCard-amount, or ByGiftCard-amount etc.
  // first we remove any classes
  $(element).find('option').each(function () {$(pay_input).removeClass($(this).val() + '-amount');} );
  // then we add the currently selected value as a class, i.e. PayBox-amount
  $(pay_input).addClass($(element).val() + '-amount');
  if ($(element).val() == "ByCard") {
    if (typeof bycard_show != 'undefined') {
      bycard_show();
    }
    
    $(pay_input).val(cardTotal);
    $(pay_input).addClass('bycard-amount');
    display_change('function validatePaymentMethod');
  } else {
    $(pay_input).val(cardTotal);
  }
}

// this is only for text based pole displays
function displayChangeToCustomer() {
    if ( !useMimo() && isSalor() ) {
      given = parseFloat(get_payment_total());
      given = sprintf(" %s %6.2f", i18nunit, given);
      change = parseFloat($('#complete_order_change').html().replace(',','.').substring(1));
      change = sprintf(" %s %6.2f", i18nunit, change);
      blurb_line1 = (i18n_money_given + '       ').substring(0,9);
      blurb_line2 = (i18n_money_change + '       ').substring(0,9);
      Salor.poleDancer(Register.pole_display, blurb_line1 + given + blurb_line2 + change );
    }
}

function serializePayments() {
  var returnArr = [];
  $.each($(".payment-method"), function(){
    var index = $(this).attr('id').split("_")[2];
    var method = $(this).val();
    var amount = $("#payment_amount_" + index).val();
    returnArr.push(method + "=" + amount);
  });
  return returnArr.join("&");
}

function checkAndDisplayChange(from) {
  if ( ! from ) {
    from = 'checkAndDisplayChange:from not set';
  }
  if ($('.payment-amount').is(":visible")) {
     display_change(from);
  }
}


/*
 *  Allows us to latch onto events in the UI for adding menu items, i.e. in this case, customers, but later more.
 */
function emit(msg,packet) {
  $('body').triggerHandler({type: msg, packet:packet});
}



function connect(unique_name,msg,fun) {
  var pcd = _get('plugin_callbacks_done');
  if (!pcd)
    pcd = [];
  if (pcd.indexOf(unique_name) == -1) {
    $('body').on(msg,fun);
    pcd.push(unique_name);
  }
  _set('plugin_callbacks_done',pcd)
}
function _get(name,context) {
  if (context) {
    // if you pass in a 3rd argument, which should be an html element, then that is set as teh context.
    // this ensures garbage collection of the values when that element is removed.
    return $.data(context[0],name);
  } else {
    return $.data(document.body,name);
  }
}
function _set(name,value,context) {
  if (context) {
    // if you pass in a 3rd argument, which should be an html element, then that is set as teh context.
    // this ensures garbage collection of the values when that element is removed.
    return $.data(context[0],name,value);
  } else {
    return $.data(document.body,name,value);
  } 
}
function scroll_to(element, speed) {
  target_y = $(window).scrollTop();
  current_y = $(element).offset().top;
  if (settings.workstation) {
    do_scroll((current_y - target_y)*1.05, speed);
  } else {
    window.scrollTo(0, current_y);
  }
}

function scroll_for(distance, speed) {
  do_scroll(distance, speed);
}

function  in_array_of_hashes(array,key,value) {
  for (var i in array) {
    if (array[i][key]) {
      try {
        if (array[i][key] == value) {
          return true;
        } else if (array[i][key].indexOf(value) != -1){
          return true;
        }
      } catch (e) {
        return false;
      }
    }
  }
  return false;
}

function do_scroll(diff, speed) {
  window.scrollBy(0,diff/speed);
  newdiff = (speed-1)*diff/speed;
  scrollAnimation = setTimeout(function(){ do_scroll(newdiff, speed) }, 20);
  if(Math.abs(diff) < 5) { clearTimeout(scrollAnimation); }
}

function debug(message) {
  if ( debugmessages.length > 7 ) { debugmessages.shift(); }
  debugmessages.push(message);
  $('#messages').html(debugmessages.join('<br />'));
}


function toggle_all_option_checkboxes(source) {
  if ($(source).attr('checked') == 'checked') {
    $('input.category_checkbox:checkbox').attr('checked',true);
  } else {
    $('input.category_checkbox:checkbox').attr('checked',false);
  }
}

function date_as_ymd(date) {
  return date.getFullYear() + '-' + (date.getMonth()+1) + '-' + date.getDate();
}
function get_date(str) {
  return new Date(Date.parse(str));
}
/*
  _fetch is a quick way to fetch a result from the server.
 */
function _fetch(url,callback) {
  $.ajax({
    url: url,
    context: window,
    success: callback
  });
}
/*
 *  _push is a quick way to deliver an object to the server
 *  It takes a data object, a string url, and a success callback.
 *  Additionally, you can pass, after those three an error callback,
 *  and an object of options to override the options used with
 *  the ajax request.
 */
function _push(object) {
  var payload = null;
  var callback = null;
  var error_callback = function (jqXHR,status,err) {
    //console.log(jqXHR,status,err.get_message());
  };
  var user_options = {};
  var url;
  for (var i = 0; i < arguments.length; i++) {
    switch(typeof arguments[i]) {
      case 'object':
        if (!payload) {
          payload = {currentview: 'push', model: {}}
          $.each(arguments[i], function (key,value) {
            //console.log(key,value);
            payload[key] = value;
          });
        } else {
          user_options = arguments[i];
        }
        break;
      case 'function':
        if (!callback) {
          callback = arguments[i];
        } else {
          error_callback = arguments[i];
        }
        break;
      case 'string':
        url = arguments[i];
        break;
    }
  }
  options = { 
    context: window,
    url: url, 
    type: 'post', 
    data: payload, 
    timeout: 20000, 
    success: callback, 
    error: error_callback
  };
  if (typeof user_options == 'object') {
    $.each(user_options, function (key,value) {
      options[key] = value;
    });
  }
  $.ajax(options);
}
function create_dom_element (tag,attrs,content,append_to) {
  element = $(document.createElement(tag));
  $.each(attrs, function (k,v) {
    element.attr(k, v);
  });
  element.html(content);
  if (append_to != '')
    $(append_to).append(element);
  return element;
}

/*
  Call this function on an input that you want to have auto complete functionality.
  requires a jquery element, a dictionary (array, or object, or hash mapping)
  options, which is an object where the only required key is the field if you use an object, or hash mapping, then a callback,
  which is what function to run when someone clicks a search result.
  
  On an input try:
  
  auto_completable($('#my_input'),['abc yay','123 ghey'],{},function (result) {
      alert('You chose ' + result);
  });
  in the callback, $(this) == $('#my_input')
 */
function auto_completable(element,dictionary,options,callback) {
  var key = 'auto_completable.' + element.attr('id');
  element.attr('auto_completable_key',key);
  _set(key + ".dictionary",dictionary,element); // i.e. we set the context of the variable to the element so that it will be gc'ed
  _set(key + ".options", options,element);
  _set(key + ".callback", callback,element);
  element.on('keyup',function () {
    var val = $(this).val();
    var key = $(this).attr('auto_completable_key');
    var results = [];
    if (val.length > 2) {
      var options = _get(key + '.options',$(this));
      var dictionary = _get(key + ".dictionary",$(this));
      if (options.map) { 
        // We are using a hash map, where terms are organized by first letter, then first two letters
        var c = val.substr(0,1).toLowerCase();
        var c2 = val.substr(0,2).toLowerCase();
        // i.e. if the search term is doe, the check to see if dictionary['d'] is set
        if (dictionary[c]) {
          // i.e. if the search term is doe, the check to see if dictionary['do'] is set
          if (dictionary[c][c2]) {
            // i.e. we consider dictionary['do'] to be an array of objects
            for (var i in dictionary[c][c2]) {
              // we assume that you have set options { field: "name"} or some such
              if (dictionary[c][c2][i][options.field].toLowerCase().indexOf(val.toLowerCase()) != -1) {
                results.push(dictionary[c][c2][i]);
              }
            }
          }
        }
      } else { // We assume that it's just an array of possible values
        for (var i = 0; i < dictionary.length; i++) {
          if (options.field) {
            if (dictionary[i][options.field].indexOf(val.toLowerCase()) != -1) {
              results.push(dictionary[i])
            } 
          } else {
            if (dictionary[i].indexOf(val.toLowerCase()) != -1) {
              results.push(dictionary[i])
            } 
          }
        }
      }
    }
    auto_completable_show_results($(this),results);
  });
}
function auto_completable_show_results(elem,results) {
  $('#auto_completable').remove();
  if (results.length > 0) {
    var key = elem.attr('auto_completable_key');
    var options = _get(key + '.options',elem);
    ac = create_dom_element('div',{id: 'auto_completable'},'',$('body'));
    var offset = elem.offset();
    var css = {left: offset.left, top: offset.top + elem.outerHeight(), width: elem.outerWidth() + ($.support.boxModel ? 0 : 2)};
    ac.css(css);
    for (var i in results) {
      var result = results[i];
      var div = create_dom_element('div',{'class': 'result'},result[options.field],ac);
      // i.e. we set up the vars we will need on the callback on the element in context
      _set('auto_completable.result',result,div);
      _set('auto_completable.target',elem,div);
      div.on('mousedown', function () {
        var target = _get('auto_completable.target',$(this));
        var result = _get('auto_completable.result',$(this));
        var key = target.attr('auto_completable_key');
        var callback = _get(key + ".callback",target);
        callback.call(target,result,$(this)); //i.e. the callback will be executed with the input as this, the result is the first argument
        // the last optional argument will be the origin of the event, i.e. the div
        $('#auto_completable').remove();
      });
    }
  }
}

function days_between_dates(from, to) {
  var days = Math.floor((Date.parse(to) - Date.parse(from)) / 86400000);
  if (days == 0)
    days = 0
  return days;
}
function _log(arg1,arg2,arg3) {
 //console.log(arg1,arg2,arg3);
}
/* Adds a delete/X button to the element. Type options  are right and append. The default callback simply slides the element up.
 if you want special behavior on click, you can pass a closure.*/
function deletable(elem,type,callback) {
  if (typeof type == 'function') {
    callback = type;
    type = 'right'
  }
  if (!type)
    type = 'right';
  if ($('#' + elem.attr('id') + '_delete').length == 0) {
    var del_button = create_dom_element('div',{id: elem.attr('id') + '_delete', 'class':'delete', 'target': elem.attr('id')},'X',elem);
    if (!callback) {
      del_button.on('click',function () {
        $('#' + $(this).attr('target')).slideUp();
      });
    } else {
      del_button.on('click',callback);
    }
  } else {
    var del_button = $('#' + elem.attr('id') + '_delete');
    if (callback) {
      del_button.unbind('click').on('click',callback);
    }
  }
  var offset = elem.offset();
  if (type == 'right') {
    offset.left += elem.outerWidth() - del_button.outerWidth() - 5;
    offset.top += 5
    del_button.offset(offset);
  } else if (type == 'append') {
    elem.append(del_button);
  }
  
}
/* Pass in a hex code to get back an object of red, green, blue*/
function to_rgb(hex) {
  var h = (hex.charAt(0)=="#") ? hex.substring(1,7):h;
  var r = parseInt(h.substring(0,2),16);
  var g = parseInt(h.substring(2,4),16);
  var b = parseInt(h.substring(4,6),16);
  return {red: r, green: g, blue: b};
}
window.retail = {container: $(window)};
window.shared = {
  element:function (tag,attrs,content,append_to) {
    if (attrs["id"] && $('#' + attrs["id"]).length != 0) {
      var elem = $('#' + attrs["id"]);
      _set('existed',true,elem);
      return elem;
    } else {
      return create_dom_element(tag,attrs,content,append_to)
    }
  },
  date: {
    hm: function (date,sep) {
      if (!date)
        date = new Date();
      if (!sep)
        sep = '';
      return [shared.helpers.pad(date.getHours(),'0',2),shared.helpers.pad(date.getMinutes(),'0',2)].join(sep);
    },
    ymd: function (date,sep) {
      if (!sep)
        sep = '';
      return [
        date.getFullYear(),
        shared.helpers.pad(date.getMonth() + 1,'0',2),
        shared.helpers.pad(date.getDate(),'0',2)
      ].join(sep); 
    },
    ymdhm: function (date,sep) {
      if (!sep)
        sep = '';
      return [
      date.getFullYear(),
      shared.helpers.pad(date.getMonth() + 1,'0',2),
      shared.helpers.pad(date.getDate(),'0',2),
      shared.helpers.pad(date.getHours(),'0',2),
      shared.helpers.pad(date.getMinutes(),'0',2)
      ].join(sep); 
    }
  },
  most_common: function (string,callback,cap,matches,start,start2,keys,results,sorted) {
    var time_start = new Date();
    if (!matches)
      matches = string.match(/(.{4,4})/g);
    if (!results)
      results = {};
    if (!start)
      start = 0;
    for (var i = start; i < matches.length; i++) {
      if (!results[matches[i]])
        results[matches[i]] = 1
      else
        results[matches[i]] += 1
      var now = new Date();
      if ((now - time_start) > 100) {
        setTimeout(function () {
          shared.most_common(string,callback,cap,matches,i+1,null,null,results,null);
        },50);
        return;
      }
    }
    if (!start2)
      start2 = 0;
    if (!keys)
      keys = Object.keys(results);
    if (!sorted)
      sorted = [];
    for (var j = start2; j < keys.length; j++) {
      sorted.push([keys[j],results[keys[j]]]);
      if ((now - time_start) > 100) {
        setTimeout(function () {
          shared.most_common(string,callback,cap,matches,matches.length,j+1,keys,results,sorted);
        },50);
        return;
      }
    }
    sorted.sort(function (a,b){
      if (a[1] > b[1]) {
        return 1;
      }
      if (a[1] < b[1]) {
        return -1;
      }
      return 0;
    });
//     console.log(sorted);
    var new_sorted = [];
    if (!cap)
      cap = 10;
    if (sorted.length < cap)
      cap = sorted.length - 1;
    for (var ii = sorted.length-1; ii > sorted.length - cap; ii--) {
      new_sorted.push(sorted[ii][0]);
    }
    callback.call({},new_sorted);
  },
  compress: function (string,dictionary,callback,start,timer) {
    var time_start = new Date();
    if (!timer)
      timer = new Date();
    if (!start) {
      start = 0;
      //console.log("Compressing: ",string.length," chars");
    }
    for (var i = start; i < dictionary.length; i++) {
      if (dictionary[i][1] == '')
        break;
      var reg = new RegExp(dictionary[i][1],'g');
      string = string.replace(reg,dictionary[i][0]);
      var now = new Date();
      if ((now - time_start) > 80) {
        setTimeout(function () {
          shared.compress(string,dictionary,callback,i+1,timer);
        },50);
        return;
      }
    }
    //console.log("Compression took: ",((new Date()) - timer) / 1000,'s');
    callback.call({},string);
  },
  decompress: function (string,dictionary,callback,start,timer) {
    var time_start = new Date();
    if (!timer)
      timer = new Date();
    if (!start) {
      start = 0;
    }
    for (var i = start; i < dictionary.length; i++) {
      if (dictionary[i][1] == '')
        break;
      var reg = new RegExp(dictionary[i][0],'g');
      string = string.replace(reg,dictionary[i][1].replace('\\]',']').replace('\\[','['));
      var now = new Date();
      if ((now - time_start) > 80) {
        setTimeout(function () {
          shared.decompress(string,dictionary,callback,i+1,timer);
        },50);
        return;
      }
    }
    //console.log("decompression took: ",((new Date()) - timer) / 1000,'s');
    callback.call({},string);
  },
  math: {
    between: function (needle,s1,s2) {
      s1 = parseInt(s1);
      s2 = parseInt(s2);
      needle = parseInt(needle);
      //console.log(needle,s1,s2);
      if (needle >= s1 && needle <= s2) {
        //console.log('returning true');
        return true;
      }
      return false;
    },
    rand: function (num) {
      if (!num) {
        num = 10000;
      }
      return Math.floor(Math.random() * num);
    },
    to_currency: function (number,separator,unit) {
      var match, property, integerPart, fractionalPart;
      var settings = {         precision: 2,
      unit: i18n.currency_unit,
      separator: i18n.decimal_separator,
      delimiter :'',
      precision: 2
      };
      if ( separator ) {
        settings.separator = separator;
      }
      if ( unit ) {
        settings.unit = unit;
      }
      match = number.toString().match(/([\+\-]?[0-9]*)(.[0-9]+)?/);
      
      if (!match) return;
      
      integerPart = match[1].replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1" + settings.delimiter);
      fractionalPart = match[2] ? (match[2].toString() + "000000000000").substr(1, settings.precision) : "000000000000".substr(1, settings.precision);
      
      return settings.unit + integerPart + ( settings.precision > 0 ? settings.separator + fractionalPart : "");
    },
    to_percent: function (number,separator) {
      unit = '%';
      var match, property, integerPart, fractionalPart;
      var settings = {         precision: 2,
        unit: i18n.currency_unit,
        separator: i18n.decimal_separator,
        delimiter :'',
        precision: 0
      };
      if ( separator ) {
        settings.separator = separator;
      }
      if ( unit ) {
        settings.unit = unit;
      }
      match = number.toString().match(/([\+\-]?[0-9]*)(.[0-9]+)?/);
      
      if (!match) return;
      
      integerPart = match[1].replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1" + settings.delimiter);
      fractionalPart = match[2] ? (match[2].toString() + "000000000000").substr(1, settings.precision) : "000000000000".substr(1, settings.precision);
      
      return '' + integerPart + ( settings.precision > 0 ? settings.separator + fractionalPart : "") + settings.unit;
    },
    to_float: function (str, returnString) {
      if (str == '' || !str) {return 0.0;}
      if (returnString == null) returnString = false;
      if (typeof str == 'number') {
        return shared.math.round(str);
      }
      if (str.match(/\d+\.\d+\,\d+/)) {
        str = str.replace('.','');
      }
      var ac = [0,1,2,3,4,5,6,7,8,9,'.',',','-'];
      var nstr = '';
      for (var i = 0; i < str.length; i++) {
        c = str.charAt(i);
        if (inArray(c,ac)) {
          if (c == ',') {
            nstr = nstr + '.';
          } else {
            nstr = nstr + c;
          }
        }
      }
      return (returnString) ? nstr : shared.math.round(parseFloat(nstr));
    }, // end to_float
    round: function (Number, DecimalPlaces) {
      if (!DecimalPlaces)
        DecimalPlaces = 2
      return Math.round(parseFloat(Number) * Math.pow(10, DecimalPlaces)) / Math.pow(10, DecimalPlaces);
    }
  },
  create: {
    plus_button: function (callback) {
      var button = create_dom_element('div',{},'','');
      button.addClass('add-button');
      button.on('mousedown',callback);
      return button;
    },
    finish_button: function (callback) {
      var button = create_dom_element('div',{},'','');
      button.addClass('finish-button');
      button.on('mousedown',callback);
      return button;
    }
  },
  draw: {
    /* returns a happy, centered dialog that you can use to display stuff */
    dialog: function (title,id,clear) {
      var dialog = shared.element('div',{id: id},'',$('body'));
      dialog.addClass('salor-dialog');
      dialog.css({width: retail.container.width() * 0.50, height: retail.container.height() * 0.30,'z-index':11});
      if (_get('existed',dialog)) {
        dialog.html('');
        _set('existed',false,dialog);
      }
      var pad_div = create_dom_element('h2',{},title,dialog);
      dialog.append('<hr />');
      pad_div.addClass('header');
      deletable(dialog,function () { $(this).parent().remove()});
      shared.helpers.center(dialog, $(window));
      return dialog;
    },
    loading: function (predraw,align_to) { //we need to predraw this element if we can because it loads an asset
      if (!align_to) {
        align_to = $(window);
      }
      //console.log('showing loader');
      var loader = shared.element('div',{id: 'loader'},'',$('body'));    
      loader.show();
      shared.helpers.center(loader,align_to);
      _set('retail.loader_shown',true);
      _set('retail.show_loading',false);
    },
    hide_loading: function () {
      //console.log('hiding loader');
      var loader = shared.element('div',{id: 'loader'},'',$('body')); 
      loader.hide();
      _set('retail.loader_shown',false);
      _set('retail.show_loading',false);
    },
    option: function (options,callbacks) {
      if (!options.value)
        options.value = '';
      var div = shared.element('div',{id: 'option_' + options.name}, '', options.append_to);
      div.addClass('options-row');
      div.append('<div class="option-name">' + options.title + '</div>');
      var div2 = shared.element('div',{}, '', div);
      div2.addClass('option-input');
      var input = shared.element('input',{id: 'option_' + options.name + '_input', type:'text'},'',div2);
      input.on("click",function () {
        var inp = $(this);
        setTimeout(function () {
          inp.select();
        },55);
      });
      input.addClass('option-actual-input');
      var div3 = shared.element('div',{id: 'option_' + options.name + '_button'}, 'OK', div);
      div3.addClass('option-button');
      div3.on("click",callbacks.click);
      input.val(options.value);
      input.on('keyup',callbacks.keyup);
      input.focus(callbacks.focus);
      input.blur(callbacks.blur);
      return div;
    },
    check_option: function (options,callbacks) {
      var div = shared.element('div',{id: 'option_' + options.name.replace(/\s/,'')}, '', options.append_to);
      div.addClass('options-row');
      div.append('<div class="option-name">' + options.title + '</div>');
      var div2 = shared.element('div',{}, '', div);
      div2.addClass('option-input');
      var input = shared.element('input',{id: 'option_' + options.name.replace(/\s/,'') + '_input', type:'checkbox'},'',div2);
      input.addClass('option-actual-input');
      input.attr('checked',options.value);
      input.change(callbacks.change);
      input.checkbox();
      return div;
    },
    select_option: function (options) {
      var div = shared.element('div',{id: 'option_' + options.name.replace(/\s/,'')}, '', options.append_to);
      div.addClass('options-row');
      div.append('<div class="option-name">' + options.title + '</div>');
      var div2 = shared.element('div',{}, '', div);
      div2.addClass('option-input option-select-input');
      for (var i = 0; i < options.selections.length; i++) {
        var selection = options.selections[i];
        var select = shared.element('select',{id: 'option_' + selection.name.replace(/\s/,'') + '_' + i},'',div2);
        select.addClass('option-actual-input');
        for (var attr in selection.attributes) {
          select.attr(attr,selection.attributes[attr]);
        }
        shared.element('option',{value: ''},i18n.views.single_words.choose,select);
        for (var key in selection.options) {
          var opt = shared.element('option',{value: key},selection.options[key],select);
          if (selection.value == key) {
            opt.attr('selected',true);
          }
        }
        select.on('change',selection.change);
      }
      return div;
    },
  },
  helpers: {
    align: function (obj1,obj2,target1,target2) {
      if (!target1) {
        target1 = obj1;
      }
      if (!target2) {
        target2 = obj1;
      }
      if (obj1.outerWidth() > obj2.outerWidth()) {
        target2.css({'padding-left': obj1.outerWidth() - obj2.outerWidth()})
      } else {
        target1.css({'padding-left': obj2.outerWidth() - obj1.outerWidth()})
      }
    },
    pad: function (val,what,length,orientation) {
      val = val.toString();
      if (!orientation)
        orientation = 'left';
      while (val.length < length) {
        if (orientation == 'left')
          val = what + val;
        else
          val = val + what;
      }
      return val;
    },
    paginator: function (elem,result_func) {
      elem.find('.result').remove();
      if (!_get('start',elem)) {
        _set('start',0,elem);
      }
      if (result_func) {
        _set('result_func',result_func,elem);
      } else {
        result_func = _get('result_func',elem);
      }
      var start = _get('start',elem);
      var page_size = _get('page_size',elem);
      if (!page_size) {
        page_size = 5;
      }
      var results = _get('results',elem);
      var offset = elem.offset();
      //console.log("paginating",start,page_size,results.length);
      var width = (elem.width() / 10);
      if (width > 35) {
        width = 35;
      }
      var left_tab = shared.element('div',{id: 'paginator_left_tab'},'<',elem);
      left_tab.css({height: (elem.height() / 3), width: width });
      left_tab.offset({left: offset.left - left_tab.outerWidth() + 5});
      if (!_get('existed',left_tab)) {
        left_tab.on('mousedown',function () {
          var start = _get('start',$(this).parent());
          var next = start - page_size;
          if (next < 0) {
            next = 0;
          }
          _set('start',next,elem);
          shared.helpers.paginator(elem,result_func);
        });
      }
      
      var right_tab = shared.element('div',{id: 'paginator_right_tab'},'>',elem);
      right_tab.css({height: (elem.height() / 3), width: width });
      right_tab.offset({left: offset.left + elem.outerWidth() - 5});
      if (!_get('existed',right_tab)) {
        right_tab.on('mousedown',function () {
          var start = _get('start',$(this).parent());
          var results = _get('results',elem);
          var next = start + page_size;
          if (next >= results.length) {
            next = start;
          }
          _set('start',next,elem);
          shared.helpers.paginator(elem,result_func);
        });
      }
      elem.find('.result-count').remove();
      elem.find('.header').append("<span class='result-count'>("+results.length+")</span>");
      
      for (var i = start; i < start + page_size; i++) {
        var obj = results[i];
        if (obj) {
          result_func.call(elem,obj);
        }
      }
    },
    merge: function (obj1,obj2) {
      if (obj1 == null)
        return obj2
      if (obj1 instanceof Object && obj2 instanceof Object) {
        for (var key in obj2) {
          if (obj1[key]) {
            if (obj1[key] instanceof Object && obj2[key] instanceof Object) {
              obj1[key] = shared.helpers.merge(obj1[key],obj2[key]);
            } else {
              obj1[key] = obj2[key];
            }
          } else {
            obj1[key] = obj2[key];
          }
        }
      } // end if
      return obj1;
    },
    to_inline_block: function (elem) {
      elem.css({position: 'relative', display: 'inline-block'});
      return elem;
    },
    expand: function (elem,amount,direction) {
      if (!direction)
        direction = 'both';
      if (direction == 'both' || direction == 'vertical') {
        elem.css({height: elem.outerHeight() + (elem.outerHeight() * amount)});
      }
      if (direction == 'both' || direction == 'horizontal') {
        elem.css({width: elem.outerWidth() + (elem.outerWidth() * amount)});
      }
    },
    shrink: function (elem,amount,direction) {
      if (!direction)
        direction = 'both';
      if (direction == 'both' || direction == 'vertical') {
        elem.css({height: elem.outerHeight() - (elem.outerHeight() * amount)});
      }
      if (direction == 'both' || direction == 'horizontal') {
        elem.css({width: elem.outerWidth() - (elem.outerWidth() * amount)});
      }
    },
    /* Center an element on the page, second argument is the element to center it to*/
    center: function (elem,center_to_elem,add_offset) {
      if (!center_to_elem)
        center_to_elem = $(window);
      var offset = center_to_elem.offset();
      if (!offset) {
        offset = {top: 0, left: 0};
      }
      var width = elem.outerWidth();
      var height = elem.outerHeight();
      var swidth = center_to_elem.width();
      var sheight = center_to_elem.height();
      sheight = Math.floor((sheight / 2) - (height / 2));  
      elem.css({position: 'absolute'});
      var ntop = offset.top + sheight;
      var nleft = offset.left + Math.floor((swidth / 2) - (width / 2));
      if (add_offset) {
        ntop += add_offset.top;
        nleft += add_offset.left;
      }
      var new_offset = {top: ntop, left: nleft};
      elem.offset(new_offset);
    }, //end center
    bottom_right: function (elem,center_to_elem,pad) {
      var offset = center_to_elem.offset();
      offset.top += center_to_elem.height() - elem.outerHeight();
      offset.left += center_to_elem.width() - elem.outerWidth();
      if (pad) {
        offset.top += pad.top;
        offset.left += pad.left;
      }
      elem.css({position: 'absolute'});
      elem.offset(offset);
    },
    top_left: function (elem,center_to_elem,pad) {
      elem.css({position: 'absolute'});
      var offset = center_to_elem.offset();
      if (pad) {
        offset.top += pad.top;
        offset.left += pad.left;
      }
      elem.offset(offset);
    },
    top_right: function (elem,center_to_elem,pad) {
      elem.css({position: 'absolute'});
      var offset = center_to_elem.offset();
      offset.left += center_to_elem.width() - elem.outerWidth();
      if (pad) {
        offset.top += pad.top;
        offset.left += pad.left;
      }
      elem.offset(offset);
    },
    position_rememberable: function (elem) {
      var key = 'position_rememberable.' + elem.attr('id');
      var position = JSON.parse(localStorage.getItem(key));
      elem.css({position: 'absolute'});
      if (!position) {
        //console.log('setting to offset');
        position = elem.offset();
        localStorage.setItem(key, JSON.stringify(position));
      } else {
        elem.offset(position);
      }
      elem.draggable({
        stop: function () {
          //console.log('saving position',key,$(this).offset());
          localStorage.setItem(key, JSON.stringify($(this).offset()));
        }
      });
    }
  }, // end helpers
  callbacks: {
    on_focus: function () {
      $('.has-focus').removeClass('has-focus');
      $(this).addClass('has-focus');
    },
  },
  control: {
    task_manager: function (task_set) {
      var self = this;
      this._task_set = task_set;
      this.add = function (name,callback,priority,permanent,context) {
        for (var i = 0; i < self._task_set.length; i++) {
          if (self._task_set[i].name == name) {
            //console.log('that task is already scheduled');
            return;
          }
        }
        var task = {
          name: name,
          callback: callback,
          priority: priority,
          is_permanent: permanent,
          context: context
        }
        self._task_set.push(task);
        self._task_set.sort(function (a,b) {
          if (a.priority < b.priority)
            return -1
          if (a.priority == b.priority)
            return 0
          if (a.priority > b.priority)
            return 1
        });
      }
      this.run = function () {
        //console.log('TaskManager Runnging');
        var time_start = new Date();
        var times = self._task_set.length;
        for (var i = 0; i < times; i++) {
          t = self._task_set.reverse().pop();
          self._task_set.reverse();
          self.run_task(t);
          var now = new Date();
          if (now - time_start > 150) {
            return;
          }
        }
      }
      this.run_task = function (t) {
        //console.log('calling',t);
        t.callback.call(t.context);
        if (t.is_permanent) {
          this._task_set.push(t);
        }
      }
    }
  },
} // end shared
