














var shipments = {
  draw: {
    shipments: function (shipments_json) {
      var target = shared.element('div',{id: 'shipments_container'},'',''); //already defined in the html
      target.html();
      var row = shared.element('div',{class: 'shipment-row'},'',target);
      var name = shared.element('div',{class: 'shipment-wide'},i18n.activerecord.attributes.name,row);
      var paid = shared.element('div',{class: ''},'Paid',row);
      target.append("<br />");
      $.each(shipments_json,function (k,shipment) {
        var row = shared.element('div',{class: 'shipment-row'},'',target);
        var name = shared.element('div',{class: 'shipment-wide shipment-name'},shipment.name,row);
        var paid = shared.element('div',{class: 'shipment-paid'},shipment.paid.toString(),row);
        target.append("<br />");
      });
    }
  }
};