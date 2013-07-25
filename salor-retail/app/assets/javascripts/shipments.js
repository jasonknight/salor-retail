$(function() {
  $('#shipments_form input').on('click', function() {
    echo("Setting onbeforeunload");
    window.onbeforeunload = shipmentsOnNavigateAway;
  });
  
  $('#shipments_form input').keypress(function(e) {
    if (e.which == 13) {
    }
    return false;
  });
});

function shipmentsOnNavigateAway() {
  return i18n.views.notice.save_before;
}




var shipments = {
  draw: {
    shipmentItems: function (shipment_items_json) {
      var container = shared.element('div',{id: 'shipment_items_container'},'','');
      $.each(shipment_items_json,function (k,v) {
        var row = shared.element('div',{class: 'shipment-row'},'',container);
        var name = shared.element('div',{class: 'shipment-wide shipment-name'},shipment.name,row);
        var paid = shared.element('div',{class: 'shipment-paid'},shipment.paid.toString(),row);
        container.append("<br />");
      });
    }
  }
};