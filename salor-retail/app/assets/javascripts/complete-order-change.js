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

function checkAndDisplayChange(from) {
  if ( ! from ) {
    from = 'checkAndDisplayChange:from not set';
  }
  if ($('.payment-amount').is(":visible")) {
     display_change(from);
  }
}