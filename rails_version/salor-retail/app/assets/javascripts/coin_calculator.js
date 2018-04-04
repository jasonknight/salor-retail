sr.fn.coin_calculator.setup = function() {
  var elem, _i, _len, _ref, _results;

  _ref = $('.eod-calculator-input');
  _results = [];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    elem = _ref[_i];
    if (!$(elem).hasClass('calculator-done')) {
      $(elem).on('keyup', function() {
        sr.fn.coin_calculator.displayTotal();
        return sr.fn.debug.ajaxLog({
          log_action: 'coin_calculator',
          called_from: $(this).attr('id') + "->" + $(this).val()
        });
      });
      _results.push($(elem).addClass('calculator-done'));
    } else {
      _results.push(void 0);
    }
  }
  return _results;
}

sr.fn.coin_calculator.displayTotal = function() {
  var cls, diff, elem, ttl, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2;

  var calculator_total = 0;
  _ref = $('.eod-calculator-input');
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    elem = _ref[_i];
    ttl = parseInt(elem.value) * parseFloat($(elem).attr('amount'));
    if (ttl > 0) {
      calculator_total += ttl;
    }
  }
  calculator_total = Math.round(calculator_total * 100) / 100;
  _ref1 = ['.eod-drawer-total', '.eod-calculator-total'];
  for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
    cls = _ref1[_j];
    $(cls).removeClass('eod-error');
  }
  _ref2 = ['.eod-drawer-total', '.eod-calculator-total'];
  for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
    cls = _ref2[_k];
    $(cls).removeClass('eod-ok');
  }
  $('.eod-calculator-difference').html(sr.fn.math.toCurrency(0));
  diff = 0;
  if (sr.data.session.drawer.amount > calculator_total) {
    diff = Math.round((sr.data.session.drawer.amount - calculator_total) * 100) / 100;
    $('.eod-calculator-total').addClass('eod-error');
  }
  if (calculator_total > sr.data.session.drawer.amount) {
    diff = Math.round((calculator_total - sr.data.session.drawer.amount) * 100) / 100;
    $('.eod-drawer-total').addClass('eod-error');
  }
  $('.eod-calculator-difference').html(sr.fn.math.toCurrency(diff));
  return $('.eod-calculator-total').html(sr.fn.math.toCurrency(calculator_total));
};