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

function addCashAmount() {
  if (complete_total == 0) return;
  var addAmount = toFloat($(this).val());
  var curAmount = toFloat($("#complete_in_cash").val());
  $("#complete_in_cash").val(curAmount + addAmount);
  display_change('function addCashAmount');
  focusInput($("#complete_in_cash"));
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

function getByCardAmount() {
  var val = 0;
  $(".payment-method").each(function () {
    var id = $(this).attr("id").replace("type","amount");
    if ($(this).val() == "ByCard") {
        val = $('#' + id).val();
    }
  });
  return val;
}


