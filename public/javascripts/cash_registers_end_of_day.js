(function() {
  var calculator_total, dt;

  window.Drawer || (window.Drawer = {});

  calculator_total = 0;

  dt = Drawer.amount;

  window.displayCalculatorTotal = function() {
    var cls, diff, elem, ttl, _i, _j, _k, _len, _len2, _len3, _ref, _ref2, _ref3;
    calculator_total = 0;
    _ref = $('.eod-calculator-input');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      elem = _ref[_i];
      ttl = parseInt(elem.value) * toFloat($(elem).attr('amount'));
      if (ttl > 0) calculator_total += ttl;
    }
    calculator_total = Math.round(calculator_total * 100) / 100;
    _ref2 = ['.eod-drawer-total', '.eod-calculator-total'];
    for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
      cls = _ref2[_j];
      $(cls).removeClass('eod-error');
    }
    _ref3 = ['.eod-drawer-total', '.eod-calculator-total'];
    for (_k = 0, _len3 = _ref3.length; _k < _len3; _k++) {
      cls = _ref3[_k];
      $(cls).removeClass('eod-ok');
    }
    $('.eod-calculator-difference').html(toCurrency(0));
    diff = 0;
    if (Drawer.amount > calculator_total) {
      diff = Math.round((Drawer.amount - calculator_total) * 100) / 100;
      $('.eod-calculator-total').addClass('eod-error');
    }
    if (calculator_total > Drawer.amount) {
      diff = Math.round((calculator_total - Drawer.amount) * 100) / 100;
      $('.eod-drawer-total').addClass('eod-error');
    }
    $('.eod-calculator-difference').html(toCurrency(diff));
    return $('.eod-calculator-total').html(toCurrency(calculator_total));
  };

  window.eodPayout = function() {
    return $.ajax({
      type: 'POST',
      url: '/vendors/new_drawer_transaction',
      data: {
        transaction: {
          amount: Drawer.amount,
          notes: 'end_of_day_payout',
          tag: 'end_of_day',
          trans_type: 'payout'
        }
      },
      dataType: 'script',
      success: function(data) {
        var cls, _i, _len, _ref, _results;
        _ref = ['.eod-drawer-total', '.eod-calculator-total', '.eod-calculator-difference'];
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          cls = _ref[_i];
          _results.push($(cls).html(toCurrency(0)));
        }
        window.location = "/vendors/end_day";
        return _results;
      },
      error: function(data, status, err) {
        return alert(err);
      }
    });
  };

  $(function() {
    var elem, _i, _len, _ref, _results;
    _ref = $('.eod-calculator-input');
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      elem = _ref[_i];
      if (!$(elem).hasClass('calculator-done')) {
        $(elem).blur(function() {
          return displayCalculatorTotal();
        });
        _results.push($(elem).addClass('calculator-done'));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  });

}).call(this);
