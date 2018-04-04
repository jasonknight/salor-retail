sr.fn.payment.add = function() {
  //  if ($(".payment-amount").size() >= payment_internal_types.length) return;
  var d = $('<div></div>');
  d.addClass('payment-method');
  
  var numMethods = $(".payment-amount").size();
  
  // selector
  var sel = $('<select name="payment_methods[][internal_type]" id="' + "payment_type_" + numMethods + '" class="payment-method">'+sr.fn.payment.getOptions()+'</select>');
  sel.on('change', function(){
    sr.fn.change.display_change();
    sr.fn.debug.ajaxLog({
      log_action: 'select_payment_method',
      button_id: sel.attr('id'),
      value: sel.val(),
      order_id: sr.data.pos_core.order.id
    });
  });
  $(sel)[0].selectedIndex = numMethods;
  //---
  
  
  // amount field
  var rest_value = sr.data.pos_core.order.total - sr.fn.payment.getTotal();
  var amount = $('<input type="text" name="payment_methods[][amount]" id="' + "payment_amount_" + numMethods + '" class="payment-amount text-input keyboardable-int" value="" size="5" /> ');
  amount.on("keyup",function (event) {
    if (event.keyCode == 13) {
      sr.fn.complete.send(!sr.data.session.cash_register.no_print);
    } else {
      sr.fn.change.display_change("payment-amount.onKeyUp " + event.which + " " + amount.val() + " " + amount.attr('id'));
    }
  });
  amount.on("click",function() {
    sr.fn.focus.set(amount);
    amount.select();
  });

  amount.val(sr.fn.math.toDelimited(rest_value));
  // ---
  
  
  sr.fn.debug.ajaxLog({
    log_action: 'add_payment_method',
    order_id: sr.data.pos_core.order.id,
    value: sel.val()
  });
  
  $("#payment_methods").append(sel).append(amount);
  $("#payment_methods").append('<br />');
  
  sr.fn.change.display_change('function add_payment_method');
  
  shared.makeSelectWidget($(sel).find("option:selected"), $(sel));
  

  sr.fn.onscreen_keyboard.makeWithOptions(amount, {
    visible: function () {
      var cls = $(sel).val() + '-amount';
      $(".ui-keyboard-preview").removeClass('payment-amount');
      if (sr.data.session.other.is_apple_device) {
        $(".ui-keyboard-preview").val("");
      }
      $('.text-input').select();
    },
    accepted: function() {
      sr.fn.change.display_change('keyboard ' + sel.val());
    }
  });
  
  setTimeout(function () {
    sr.fn.focus.set(amount);
    amount.select();
  }, 100);
}

sr.fn.payment.getOptions = function() {
  var txt = '';
  $.each(sr.data.resources.payment_method_object, function(k,v) {
    txt = txt + '<option value="' + k + '">' + v.name + '</option>';
  });
  return txt;
}

sr.fn.payment.getTotal = function() {
  var paymentTotal = 0;
  var current_payment_method_items = sr.fn.payment.getItems();
  $.each(current_payment_method_items, function(k,v) {
    var tval = sr.fn.math.toFloat(v.amount);
    paymentTotal += tval;
  });
  return paymentTotal;
}

sr.fn.payment.getItems = function() {
  var returnObj = {};
  $.each($(".payment-method"), function() {
    var id = $(this).attr('id').split("_")[2];
    var amount = $("#payment_amount_" + id).val();
    var val = $(this).val();
    returnObj[val] = {
      id: sr.data.resources.payment_method_object[val].id,
      name: sr.data.resources.payment_method_object[val].name,
      cash: sr.data.resources.payment_method_object[val].cash,
      amount: amount
    }
  });
  return returnObj;
}


