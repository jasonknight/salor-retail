window.shipments = {
  
  getShipmentItemId: function(item) {
    var id = 'shipment-item-' + item.id;
    return id;
  },
  
  submitLineItem: function(sku) {
    if (sku == "") return
    get('/shipments/add_item?shipment_id=' + Shipment.id + '&sku=' + sku, '', '');
    $('#main_shipment_sku_field').val('');
    setTimeout(function() {
      // doesn't work without timeout, JS issue
      $('#main_shipment_sku_field').focus();
    }, 1000);
    
  },
  
  updateShipment: function() {
    $('#pos_order_total').html(toCurrency(Shipment.purchase_price_total));
  },
  
  updateLineItems: function() {
    for (var i = 0; i < ShipmentItems.length; i++) {
      var item = ShipmentItems[i];
      var id = shipments.getShipmentItemId(item);
      if ($('.' + id).length != 0) {
        /* Item is in list, and we need to update it */
        console.log(item.hidden);
        if (item.hidden) {
          shipments.deleteLineItem(item);
        } else {
          shipments.updateLineItem(item);
        }
      } else {
        /* Item is not in list, we need to add it */
        shipments.addLineItem(item);
      }
    }
  },
    
  addLineItem: function(item) {
    var row_new = shipments.drawLineItemRow(item);
    $('#shipment_items_container').prepend(row_new);
  },
  
  updateLineItem: function(item) {
    var row_existing = $('#shipment_item_' + item.id);
    $('#shipment_items_container').prepend(row_existing);
    row_existing.html(shipments.drawLineItemRow(item));
  },
  
  deleteLineItem: function(item) {
    var row_existing = $('#shipment_item_' + item.id);
    row_existing.fadeOut();
  },
  
  drawLineItemRow: function(item) {
    var fields = ['sku', 'name', 'quantity', 'purchase_price', 'purchase_price_total', 'tax_profile'];
    
    var row_id = 'shipment_item_' + item.id;
    var base_id = shipments.getShipmentItemId(item);
    var row = create_dom_element('div', {id:row_id, model_id:item.id, class:base_id }, '');
    
    _set('item', item, row);
    
    for (var i = 0; i < fields.length; i++) {
      var field = fields[i];
      
      var col_id = base_id + '_' + field + '_inp';
      var col_class1 = base_id + '-' + field;
      var col_class2 = 'pos-item-' + field;
      var col = create_dom_element('div', {class:'table-cell table-column pos-item-attr', id:col_id, model_id:item.id, klass:'ShipmentItem', field:field}, '');
      col.addClass(col_class1);
      col.addClass(col_class2);
      
      // set the html of the field
      switch(field) {
        case 'sku':
          col.html(item.sku);
          break;
        case 'name':
          col.html(item.name);
          if (item.name == '?') {
            // editing a name of an existing Item is dangerous, since for the recursive import function, names are like SKUs. so we enable it only for new Items.
            make_in_place_edit(col);
          }
          break;
        case 'quantity':
          col.html(item.quantity);
          make_in_place_edit(col);
          break;
        case 'price':
          col.html(toCurrency(item.price));
          make_in_place_edit(col);
          break;
        case 'purchase_price':
          col.html(toCurrency(item.purchase_price));
          make_in_place_edit(col);
          break;
        case 'total':
          col.html(toCurrency(item.total));
          break;
        case 'purchase_price_total':
          col.html(toCurrency(item.purchase_price_total));
          break;
        case 'tax_profile':
          var tax_profile_select = shared.element('select',{class: 'si_tax_profile_select'},'',col);
          tax_profile_select.on('change',function () {
            var string = '/vendors/edit_field_on_child?id=' + item.id +'&klass=ShipmentItem' + '&field=tax_profile_id&value=' + $(this).val();
            get(string, '');
            focusInput($('#main_shipment_sku_field'));
          });
          shared.element('option',{value: ''},'',tax_profile_select); // empty option
          $.each(TaxProfiles,function (i,tax_profile) {
            shared.element('option',{value: tax_profile.id},tax_profile.name,tax_profile_select);
          });
          tax_profile_select.val(item.tax_profile_id);  // select current value
          //make_select_widget('TaxProfile',tax_profile_select);
          break;
      }
      row.append(col);
      
      

    } // end loop through fields
    
    return row;
  }
  

}