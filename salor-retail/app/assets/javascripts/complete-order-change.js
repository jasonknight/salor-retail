sr.fn.change.display_change = function(called_from) {
  var paymentTotal = sr.fn.payment.getTotal();
  var change = paymentTotal - sr.data.pos_core.order.total;
  change = sr.fn.math.round(change,2);
  if (change < 0 && sr.data.pos_core.order.total > 0 && !sr.data.pos_core.order.is_proforma) {
    change = 0;
    sr.fn.complete.allowSending(false);
  } else {
    if (sr.data.pos_core.order.is_proforma) {
      change = 0;
    }
    sr.fn.complete.allowSending(true);
  }
  $('#complete_order_change').html(sr.fn.math.toCurrency(change));
  sr.fn.debug.ajaxLog({
    log_action: 'display_change',
    order_id: sr.data.pos_core.order.id,
    paymentTotal: paymentTotal,
    ototal: sr.data.pos_core.order.total,
    change: change,
    called_from: called_from
  });
  return change;
}

sr.fn.change.show_denominations = function() {
    var center = {x: $('#complete_order').position().left - 135,y: $('#complete_order').position().top + 15};
    var doc = 99; // radius
    var cpos = {x: center.x, y: center.y }; //because the first div needs to be on top
    for (var i in i18n.pieces) {
      p = $('<div id="complete_piece_'+ i18n.pieces[i] + '">'+sr.fn.math.toCurrency(i18n.pieces[i])+'</div>');
      p.css({height: '35px',width: '125px',position: 'absolute',top: cpos.y, left: cpos.x});
      p.addClass("pieces-button shadow");
        cpos = {x: cpos.x, y: cpos.y + 54};
        p.attr('amount',i18n.pieces[i]);
        p.click(function () {
          var val = sr.fn.math.toFloat($(this).attr('amount'));
          $("#payment_amount_0").val( val );
          sr.fn.change.display_change('pieces-button ' + val);
          sr.fn.debug.ajaxLog({
            log_action: 'pieces-button',
            value: val,
            order_id: sr.data.pos_core.order.id
          });
        } );
        $('body').append(p);
    }
}

sr.fn.change.get_highest = function(num) {
  if (isNaN(num)) {
    num = 0;
  }
  if (num == 0) {
    return ['<%= t("views.forms.no_change") %>',0];
  }
  var highest_piece = i18n.pieces.length - 1;
  for (var i = i18n.pieces.length-1; i > 0; i--) {
    if (i18n.pieces[i] >= num) {
      highest_piece = i-1;
    } else {
      break;
    }
  }
  var times = Math.floor(num / i18n.pieces[highest_piece]);
  var display_line = times + ' x ' + sr.fn.math.toCurrency(i18n.pieces[highest_piece]);
  var remainder = sr.fn.math.roundNumber(num - (times * i18n.pieces[highest_piece]),2);
  return [display_line,remainder];
}

sr.fn.change.wrapDiv = function(text,cls) {
  return '<div class="' + cls + '">'+text+'</div>';
}

sr.fn.change.recommend = function(num) {
  var parts = [];

  var ret = sr.fn.change.get_highest(num);
  parts.push(sr.fn.change.wrapDiv(ret[0],'complete-recommendation-item'));
  cap = 20;
  x = 0;
  while (ret[1] > 0) {
    var ret = sr.fn.change.get_highest(ret[1]);
    parts.push(sr.fn.change.wrapDiv(ret[0],'complete-recommendation-item'));
    x = x + 1;
    if (x > cap) {
      break;
    }
  }
  $('#recommendation').html(parts.join(' '));
}

