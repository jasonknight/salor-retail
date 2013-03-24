function showCompleteOrderPopup() {
  var tmpl = getCompleteOrderTemplate();
  tmpl.dialog({
    autoOpen: true,
    height: $(window).height() * 0.8,
    width: $(window).width() * 0.8,
    modal: true,
    buttons: getCompleteOrderButtons(),
  });
  $("#payment_method_list").html('');
  completeOrderShowTotal(tmpl);
  completeOrderShowChange(tmpl);
  _set("payment_methods_used",[],getCompleteOrderTemplate());
}
function getCompleteOrderTemplate() {
  return $("#complete_order_popup");
}
function getCompleteOrderButtons() {
  return {
    "Cancel":           function () { $(this).dialog( "close" ); }, //end Cancel
    "Complete":         function () { compleOrder(false);       }, //end Complete
    "Print":            function () { compleOrder(true);        }, // end Print
  };
} // end getCompleteOrderButtons
function completeOrder(print) {
  var bValid = true;
}
function completeOrderShowTotal(tmpl) {
  var el = $('#complete_order_total');
  var w = 300;
  el.css({width: w});
  completeOrderUpdateTotal(Order.total);
}
function completeOrderShowChange(tmpl) {
  var el = $('#complete_order_change');
  var w = 300;
  el.css({width: w});
  completeOrderUpdateChange(0);
}
function completeOrderUpdateTotal(num) {
  var el = $("#complete_order_total");
  var _ttl = toCurrency(num);
  el.html(_ttl);
}
function completeOrderUpdateChange(num) {
  var el = $("#complete_order_change");
  var _ttl = toCurrency(num);
  el.html(_ttl);
}
function completeOrderRightCol() {
  return $("#complete_order_popup .content-table td.right");
}
function completeOrderAddPaymentMethod() {
  var pm = {name: "notset",internal_type: "notset"};
  var pm_options = [];
  var selected = false;
  for (var i = 0; i < PaymentMethodObjects.length; i++) {
    if (_get("payment_methods_used",getCompleteOrderTemplate()).indexOf(PaymentMethodObjects[i].internal_type) == -1 && selected == false) {
      pm = PaymentMethodObjects[i];
      pm_options.push( _.template('<option value="{{=internal_type}}" selected="true">{{= name }}</option>')(PaymentMethodObjects[i]));
      selected = true;
      continue;
    }
    pm_options.push(_.template('<option value="{{=internal_type}}">{{= name }}</option>')(PaymentMethodObjects[i]));
  }
  var tmpl = _.template($("#payment_method_template").html())({pm: pm, i: 0, options: pm_options.join("\n")});
  var row = $(tmpl);
  $("#payment_method_list").append(row);
  var select = row.find("select");
  make_select_widget("",select);
  completeOrderUpdatePaymentMethodsUsed();
  focusInput(row.find("input"));
}
function completeOrderUpdatePaymentMethodsUsed() {
  var pms_used = [];//_get("payment_methods_used",getCompleteOrderTemplate());
  $(".payment-method-select").each(function () {
    pms_used.push($(this).val());
  });
  _set("payment_methods_used",pms_used,getCompleteOrderTemplate());
}