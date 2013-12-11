sr.fn.invoice.setup = function() {
  var editable_pms = $('.editable-payment-method');
  $.each(editable_pms,function (key,pm) {
    sr.fn.invoice.editPm(pm);
  });
}

sr.fn.invoice.editPm = function(pm) {
  pm = $(pm);
  pm.click(function () {
    var dialog = shared.draw.dialog(i18n.menu.edit_tender_method,'edit_payment_method');
    
    var options = {
      name: 'payment_methods',
      title: i18n.activerecord.models.payment_method.one,
      append_to: dialog,
      selections: [
      // begin sale_types
      {
        name: 'payment_method_name',
        title: i18n.activerecord.models.payment_method.one,
        options: (function () {
          var stys = {};
          for (var t in sr.data.resources.payment_method_array) {
            var payment_method = sr.data.resources.payment_method_array[t];
            stys[payment_method[1]] = payment_method[0];
          }
          return stys;
        })(),
        change: function () {
          var string = '/vendors/edit_field_on_child?klass=PaymentMethodItem&id='+ pm.attr('model_id') +'&value=' + $(this).val() + '&field=payment_method_id'
          get(string, 'invoices.js', function() {
            location.reload();
          });
        },
        attributes: {name: i18n.activerecord.models.sale_type.one},
        value: ''
      }
      ]
    } // end var options
    
    var additional = shared.draw.select_option(options);
    additional.find('select').each(function () {shared.makeSelectWidget($(this).attr('payment_method_name'),$(this));_set('pm',pm,$(this));});
    dialog.show();
    dialog.offset({
      left: sr.data.various.mouse_x - 100,
      top: sr.data.various.mouse_y - 20
    });
    shared.helpers.expand(dialog,0.10,'vertical');
    
  });
}