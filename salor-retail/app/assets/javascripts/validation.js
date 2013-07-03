function validate_order_totals() {
  var item_total = 0.0;
  $('.pos-item-total').each(function () {
    var total = toFloat($(this).html()); 
    if ($(this).hasClass('pos-highlight') && total > 0){
      item_total = item_total - total;
      $(this).html(toCurrency(total * -1));
    } else {
      item_total = item_total + total;
    }
  }); 
  if (!toCurrency(item_total) == $('.pos-order-total').html()) {
    notify_user(i18n.headings.order_validation, 
                i18n.system.errors.order_totals_validation_failed, function () {
                  window.location = "/orders/new";
                });
  }
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