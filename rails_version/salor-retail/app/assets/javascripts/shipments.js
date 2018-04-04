sr.fn.shipments = {
  
  getShipmentItemId: function(item) {
    var id = 'shipment-item-' + item.id;
    return id;
  },
  
  submitLineItem: function(sku) {
    if (sku == "") return
    get('/shipments/add_item?shipment_id=' + sr.data.shipments.shipment.id + '&sku=' + sku, '', '');
    $('#main_shipment_sku_field').val('');
    setTimeout(function() {
      // doesn't work without timeout, JS issue
      $('#main_shipment_sku_field').focus();
    }, 1000);
    
  },
  
  updateShipment: function() {
    $('#pos_order_total').html(sr.fn.math.toCurrency(sr.data.shipments.shipment.purchase_price_total));
  },
  
  updateLineItems: function() {
    for (var i = 0; i < sr.data.shipments.shipment_items.length; i++) {
      var item = sr.data.shipments.shipment_items[i];
      var id = sr.fn.shipments.getShipmentItemId(item);
      if ($('.' + id).length != 0) {
        /* Item is in list, and we need to update it */
        console.log(item.hidden);
        if (item.hidden) {
          sr.fn.shipments.deleteLineItem(item);
        } else {
          sr.fn.shipments.updateLineItem(item);
        }
      } else {
        /* Item is not in list, we need to add it */
        sr.fn.shipments.addLineItem(item);
      }
    }
  },
    
  addLineItem: function(item) {
    var row_new = sr.fn.shipments.drawLineItemRow(item);
    $('#shipment_items_container').prepend(row_new);
  },
  
  updateLineItem: function(item) {
    var row_existing = $('#shipment_item_' + item.id);
    $('#shipment_items_container').prepend(row_existing);
    row_existing.html(sr.fn.shipments.drawLineItemRow(item));
  },
  
  deleteLineItem: function(item) {
    var row_existing = $('#shipment_item_' + item.id);
    row_existing.fadeOut();
  },
  
  drawLineItemRow: function(item) {
    var fields = ['sku', 'name', 'quantity', 'purchase_price', 'purchase_price_total', 'tax_profile'];
    
    var row_id = 'shipment_item_' + item.id;
    var base_id = sr.fn.shipments.getShipmentItemId(item);
    var row = shared.create.domElement('div', {id:row_id, model_id:item.id, clss:base_id }, '');
    
    _set('item', item, row);
    
    for (var i = 0; i < fields.length; i++) {
      var field = fields[i];
      
      var col_id = base_id + '_' + field + '_inp';
      var col_class1 = base_id + '-' + field;
      var col_class2 = 'pos-item-' + field;
      var col = shared.create.domElement('div', {clss:'table-cell table-column pos-item-attr', id:col_id, model_id:item.id, klass:'ShipmentItem', field:field}, '');
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
            sr.fn.inplace_edit.make(col);
          }
          break;
        case 'quantity':
          col.html(item.quantity);
          sr.fn.inplace_edit.make(col);
          break;
        case 'price':
          col.html(sr.fn.math.toCurrency(item.price));
          sr.fn.inplace_edit.make(col);
          break;
        case 'purchase_price':
          col.html(sr.fn.math.toCurrency(item.purchase_price));
          sr.fn.inplace_edit.make(col);
          break;
        case 'total':
          col.html(sr.fn.math.toCurrency(item.total));
          break;
        case 'purchase_price_total':
          col.html(sr.fn.math.toCurrency(item.purchase_price_total));
          break;
        case 'tax_profile':
          var tax_profile_select = shared.element('select',{clss: 'si_tax_profile_select'},'',col);
          tax_profile_select.on('change',function () {
            var string = '/vendors/edit_field_on_child?id=' + item.id +'&klass=ShipmentItem' + '&field=tax_profile_id&value=' + $(this).val();
            get(string, '');
            sr.fn.focus.set($('#main_shipment_sku_field'));
          });
          shared.element('option',{value: ''},'',tax_profile_select); // empty option
          $.each(sr.data.resources.tax_profile_object,function (i,tax_profile) {
            shared.element('option',{value: tax_profile.id},tax_profile.name,tax_profile_select);
          });
          tax_profile_select.val(item.tax_profile_id);  // select current value
          break;
      }
      row.append(col);
      
      

    } // end loop through fields
    
    return row;
  },
  
  move_item_into_stock: function( shipment_item_id, quantity, locationstring) {
    if (typeof locationstring == 'undefined') {
      // see UI. this happens when there are either no ItemStocks or no Item
      locationstring = ''
    } else if (locationstring.length == 0) {
      // when user left select empty
      return;
    }    
    var string = "/shipments/move_item_into_stock?shipment_item_id=" + shipment_item_id + "&quantity=" + quantity + "&locationstring=" + locationstring;
    get(string, 'shipments.move_item_into_stock', function() {
      location.reload();
    });
  },
  
  moveAllItemsIntoStock: function(shipment_id) {
    var string = "/shipments/move_all_items_into_stock?shipment_id=" + shipment_id;
    get(string, 'shipments.moveAllItemsIntoStock', function() {
      location.reload();
    });
  },
  

}