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
    dialog.show();
    dialog.offset({left: MX - 100, top: MY - 20});
    var options = {
      name: 'sales_type_and_countries',
      title: i18n.activerecord.attributes.name,
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
             var string = '/vendors/edit_field_on_child?id='+ Order.id +'&klass=Order&field=sale_type_id&value=' + $(this).val();
             get(string, 'invoices->payment_method_name', function () {
               //
             });
           },
           attributes: {name: i18n.activerecord.models.sale_type.one},
           value: Order.sale_type_id,
      }
      ]
    } // end var options
    var additional = shared.draw.select_option(options);
    additional.find('select').each(function () {make_select_widget($(this).attr('payment_method_name'),$(this));});
  });
}