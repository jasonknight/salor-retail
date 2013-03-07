$(function () {
  var editable_pms = $('.editable-payment-method');
  $.each(editable_pms,function (key,pm) {
    make_editabl_pm(pm);
  });
});
function make_editabl_pm(pm) {
  pm = $(pm);
  pm.click(function () {
    var dialog = shared.draw.dialog(i18n.menu.edit_tender_method,'edit_payment_method');
    
    var options = {
      name: 'payment_methods',
      title: i18n.activerecord.models.tender_method.one,
      append_to: dialog,
      selections: [
      // begin sale_types
      {
        name: 'payment_method_name',
        title: i18n.activerecord.models.tender_method.one,
        options: (function () {
          var stys = {};
          for (var t in PaymentMethods) {
            var payment_method = PaymentMethods[t];
            stys[payment_method[1]] = payment_method[0];
          }
          return stys;
        })(),
           change: function () {
             var pm = _get('pm',$(this));
             
             var string = '?pm_id=' + pm.attr('model_id') + '&pm_name=' + $(this).val();
             window.location = string;
           },
           attributes: {name: i18n.activerecord.models.sale_type.one},
           value: ''
      }
      ]
    } // end var options
    var additional = shared.draw.select_option(options);
    additional.find('select').each(function () {make_select_widget($(this).attr('payment_method_name'),$(this));_set('pm',pm,$(this));});
    // Amount
    var callbacks = {
      click: function () {
        var id = '#option_payment_method_amount_input';
        var pm = _get('pm',$('#option_payment_method_amount_input'));
        var value = $(id).val();
        var string = '?pm_id='+ pm.attr('model_id') +'&pm_amount=' + value;
        window.location = string;
      }
    };
    var options = {
      name: 'payment_method_amount',
      title: i18n.activerecord.attributes.amount,
      value: pm.attr('amount'),
      append_to: dialog
    };
    var amount = shared.draw.option(options,callbacks);
    _set('pm',pm,$('#option_payment_method_amount_input'));
    dialog.show();
    dialog.offset({left: MX - 100, top: MY - 20});
    shared.helpers.expand(dialog,0.10,'vertical');
    
  });
}