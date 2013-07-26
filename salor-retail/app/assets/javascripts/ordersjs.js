var highlightAttrs = ['sku', 'price', 'total'];

function add_item(sku, additional_params) {
  if (sku == "") return
  get('/orders/add_item_ajax?order_id=' + Order.id + '&sku=' + sku + additional_params);
  $('#main_sku_field').val('');
}

function updateOrder(order) {
  var button = $('#buy_order_button');
  if (order.buy_order) {
    $(button).addClass('pos-highlight');
    $(button).removeClass('pos-configuration');
    $('#pos_order_total').addClass("pos-highlight");
  } else {
    $(button).removeClass('pos-highlight');
    $(button).addClass('pos-configuration');
    $('#pos_order_total').removeClass("pos-highlight");
  }
  $('#pos_order_total').html(toCurrency(order.total));
  $('.complete-order-total').html(toCurrency(order.total));
  $('.order-rebate_type').html(order.rebate_type);
  $('.order-rebate').attr('model_id',order.id);
  $('.order-tag').attr('model_id',order.id);
  $('.order-rebate_type').attr('model_id',order.id);
  $('.order-rebate').html(order.rebate);
  $('.order-tag').html(order.tag);
  if (!order.lc_points > 0) {
    order.lc_points = 0;
  }
  $('.order-points').html(order.lc_points);
}

function updateOrderItems(items) {
  for (var i = 0; i < items.length; i++) {
    var item = items[i];
    var id = getOrderItemId(item);
    if ($('.' + id).length != 0) {
      /* Item is in list, and we need to update it */
      updatePosItem(item);
    } else {
      /* Item is not in list, we need to add it */
      addPosItem(item);
    }
  }
}

function addPosItem(item) {
  var row_new = drawOrderItemRow(item);
  $('.pos-table-left-column-items').prepend(row_new);
}

function updatePosItem(item) {
  var row_existing = $('#order_item_' + item.id)
  row_existing.html(drawOrderItemRow(item));
}


function drawOrderItemRow(item) {
  if (Register.hide_discounts == true) {
    var attrs = ['name', 'quantity', 'price', 'total'];
  } else {
    var attrs = ['name', 'quantity', 'price', 'rebate', 'price_reductions', 'total', 'tax'];
  }
  
  var row_id = 'order_item_' + item.id;
  var base_id = getOrderItemId(item);
  var row = create_dom_element('div', {id:row_id, model_id:item.id, item_id:item.item_id, class:base_id }, '');
  
   _set('item',item,row);
   
  for (var i = 0; i < attrs.length; i++) {
    var attr = attrs[i];
    
    var col_id = base_id + '_' + attr + '_inp';
    var col_class1 = base_id + '-' + attr;
    var col_class2 = 'pos-item-' + attr;
    var col = create_dom_element('div', {class:'table-cell table-column pos-item-attr', id:col_id, model_id:item.id, klass:'OrderItem', field:attr}, '');
    col.addClass(col_class1);
    col.addClass(col_class2);
    
    // set the html of the field
    switch(attr) {
      case 'name':
        col.html(item.name + '<br/>' + item.sku);
        break;
      case 'quantity':
        col.html(item.quantity);
        break;
      case 'price':
        switch(item.behavior) {
          case 'normal':
            col.html(toCurrency(item.price));
            break;
          case 'aconto':
            col.html(toCurrency(item.price));
            break;
          case 'coupon':
            switch(item.coupon_type) {
              case 1:
                col.html(toPercent(item.price));
                break;
              case 2:
                col.html(toCurrency(item.price));
                break;
              case 3:
                col.html('b1g1');
                break;
            }
            break;
          case 'gift_card':
            col.html(toCurrency(item.price));
            break;
        }
        break;
      case 'rebate':
        if (item.behavior != 'coupon' && item.behavior != 'gift_card' ) {
          col.html(toPercent(item.rebate));
        }
        break;
      case 'price_reductions':
        if (item.behavior == 'normal' ) {
          var contents = [];
          contents[0] = toCurrency(item.discount_amount);
          contents[1] = toCurrency(item.rebate_amount);
          contents[2] = toCurrency(item.coupon_amount);
          col.html(contents.join("<br />"));
        }
        break;
      case 'total':
        if (item.behavior != 'coupon') {
          col.html(toCurrency(item.total));
        }
        break;
      case 'tax':
        if (item.behavior != 'coupon') {
          col.html(toPercent(item.tax));
        }
        break;
    }


    // various settings of individual fields and adding of col to row
    switch(attr) {
      case 'name':
        row.append(col);
        makeItemMenu(col, row);
        break;
      case 'tax':
        var color = TaxProfiles[item.tax_profile_id].color;
        if (color != null && color != "" ) {
          col.css('background-color', color);
        } else {
          col.css('background-color', 'transparent');
        }
        row.append(col);
        break;
        
      case 'coupon_amount':
        if (item[attr] > 0) {
          col.addClass('discount_applied');
        }
        row.append(col);
        break;
        
      case 'price':
        if (item.action_applied) {
          col.addClass("pos-action-applied");
        }
        row.append(col);
        break;
        
      case 'quantity':
        make_in_place_edit(col);
        col.addClass('editme pointer no-select');
        if (Register.show_plus_minus) {
          var up = td().removeClass('jtable-cell').addClass('table-cell');
          up.html("<div><img src=\"/images/icons/up.svg\" height='32' />");
          up.addClass('pointer quantity-button');
          row.append(up);
          up.on('mousedown', function () {
            var v = toFloat($('.' + base_id + '-quantity').html()) + 1;
            var string = '/vendors/edit_field_on_child?id=' +
            item.id +'&klass=OrderItem' +
            '&field=quantity'+
            '&value=' + v;
            get(string, filename);
            focusInput($('#main_sku_field'));
          });
        }
        row.append(col);
        if (Register.show_plus_minus) {
          var down = td().removeClass('jtable-cell').addClass('table-cell');
          down.html("<div><img src=\"/images/icons/down.svg\" height='32' />");
          down.addClass('pointer quantity-button');
          row.append(down);
          down.on('mousedown', function () {
            var v = toFloat($('.' + base_id + '-quantity').html()) - 1;
            var string = '/vendors/edit_field_on_child?id=' +
            item.id +'&klass=OrderItem' +
            '&field=quantity'+
            '&value=' + v;
            get(string, filename);
            focusInput($('#main_sku_field'));
          });
        }
        break;
        
      case 'price_reductions':
        if (item.discount_amount > 0 || item.coupon_amount > 0 || item.rebate_amount > 0) {
          col.addClass('discount_applied'); //highlight
        }
        row.append(col);
        break;

      default:
        row.append(col);

    }
    
    // additional rules of field groups
    if (attr == "price" || attr == "rebate" || attr == "tax") {
      if (
        (User.role_cache.indexOf('change_prices') != -1) ||
        (User.role_cache.indexOf('manager') != -1) ||
        (item.must_change_price == true)
         ) {
        make_in_place_edit(col);
        col.addClass('editme pointer no-select');
        }
    }
    
    if (attr == "price" && item.must_change_price && item.price == 0 ) {
      setTimeout(trigger_click(col), 50);
    }
    
  
    if (item.is_buyback && highlightAttrs.indexOf(attr) != -1) {
      highlight(col);
    }

  } // end loop through attrs

  if(item.weigh_compulsory && item.quantity == 0) {
    weigh_last_item();
  }
  return row;
}

// this is a closure needed to remember the value of col in the above loop. Without closure, the variable col would change before the timout triggers. The timeout is needed for the onscreen keyboard.
var trigger_click = function(col) {
  return function() {
    col.trigger('click');
  };
};






function makeItemMenu(col, row) {
  try {
    var item = _get('item', row);
    col.unbind();
    col.mousedown(function (event) {
        if (Register.detailed_edit == true) {
          detailedOrderItemMenu(event);
          return;
        }
        $('.item-menu-div').remove();
        var menu = $("<div class='item-menu-div'></div>");
        $('body').append(menu);
        menu.css({position: 'absolute', left: event.pageX, top: event.pageY});
        var dicon = $('<div id="item_menu_delete" class="oi-menu-icon"><img src="/images/icons/delete.svg" width="31px" height="32px" /></div>');
        dicon.mousedown(function () {
            row.remove();
            get('/orders/delete_order_item?id=' + item.id, filename);
            menu.remove();
            //setScrollerState();
            focusInput($('#main_sku_field'));
        });
        menu.append(dicon);
        
        var buyback = $('<div id="item_menu_buyback" class="oi-menu-icon"><img src="/images/icons/bill.svg" width="46px" height="28px" /></div>');
        buyback.addClass('pointer');
        buyback.mousedown(function () {
            var string = '/vendors/edit_field_on_child?id=' +
                          item.id +'&klass=OrderItem' +
                          '&field=toggle_buyback'+
                          '&value=undefined';
                          get(string, filename);
                          menu.remove();
                          focusInput($('#main_sku_field'));
        }).mouseup(function () {
          focusInput($('#main_sku_field'));
        });
        menu.append(buyback);
        if (!Register.scale == '') {
          var wicon = $('<div id="item_menu_scale" class="oi-menu-icon"><img src="/images/icons/scale.svg" width="31px" height="32px" /></div>');
          wicon.mousedown(function () {
              var string = '/vendors/edit_field_on_child?id=' +
                            item.id +'&klass=OrderItem' +
                            '&field=quantity'+
                            '&value=' + Register.scale;
                            get(string, filename);
              menu.remove();
              focusInput($('#main_sku_field'));
          }).mouseup(function () {
            focusInput($('#main_sku_field'));
          });

          menu.append(wicon);
        } // end  if (!Register.scale == '') {

        var btn = $('<div id="item_menu_done" class="oi-menu-icon"><img src="/images/icons/okay.svg" width="31px" height="32px" /></div>');
        btn.mousedown(function () {
            menu.remove();
            focusInput($('#main_sku_field'));
        }).mouseup(function () {
          focusInput($('#main_sku_field'));
        });
        menu.append(btn);
    });

  } catch (err) {
    echo(err);
  }
}



window.showOrderOptions = function () {
  var dialog = shared.draw.dialog(i18n.menu.configuration + ' ID ' + Order.id,"order_options");
  
  // Customer code
  if (Order.customer) {
    var e = shared.element('div',{id:'pos_customer_div', align: 'center'},'',dialog);
    obj = Order.customer;
    lc = Order.loyalty_card;
    var name = $('<div><span class="customer_name"></span></div>');
    name.html(obj.first_name + ' ' + obj.last_name);
    var row = $('<div></div>');
    row.append(name);
    row.append('<span class="">'+i18n.activerecord.attributes.points+'</span>');
    if (!lc.points > 0) {
      lc.points = 0;
    }
    var col = $('<span id="pos-loyalty-card-points" class="loyalty-points">'+lc.points+'</span>');
    col.attr('model_id',lc.id);
    col.attr('klass','LoyaltyCard');
    col.attr('field','points');
    col.addClass('editme');
    make_in_place_edit(col);
    row.append(col);
    row.append('<span class="">'+i18n.activerecord.attributes.lc_points+'</span>');
    var col = $('<span id="pos-order-points" class="order-points">' + Order.lc_points + '</span>');
    col.attr('model_id',Order.id);
    col.attr('klass','Order');
    col.attr('field','lc_points');
    col.addClass('editme');
    make_in_place_edit(col);
    row.append(col);
    e.append(row);
  }
  // End customer code
  
  
  // OrderTag
  var callbacks = {
    click: function () {
      var id = '#option_order_tag_input';
      var value = $(id).val();
      var string = '/vendors/edit_field_on_child?id='+ Order.id +'&klass=Order&field=tag&value=' + value;
      get(string, 'showOrderOptions', function () {
        
      });
    },
    focus: function () {
      var inp = $(this);
      setTimeout(function () {
        inp.select();
      }, 170);
    }
  };
  var options = {
    name: 'order_tag',
    title: i18n.activerecord.attributes.tag,
    value: Order.tag,
    append_to: dialog
  };
  var tag = shared.draw.option(options,callbacks);
  //end order tag
  
  // Rebate
  var callbacks = {
    click: function () {
      var id = '#option_order_rebate_input';
      var value = $(id).val();
      var string = '/vendors/edit_field_on_child?id='+ Order.id +'&klass=Order&field=rebate&value=' + value;
      get(string, 'showOrderOptions');
    }
  };
  var options = {
    name: 'order_rebate',
    title: i18n.activerecord.attributes.rebate,
    value: Order.rebate,
    append_to: dialog
  };
  var rebate = shared.draw.option(options,callbacks);
  // end Rebate
  
  
  var config_table = shared.element('table',{id: 'order_item_edit_table', width: '90%', align:'center'},'',dialog);
  var config_table_rows = [ shared.element('tr',{id: 'order_item_edit_table_row_1'},'',config_table) ];
  
  var config_table_cols_left = [ shared.element('td',{id: 'order_item_edit_table_lcol_1'},'',config_table_rows[0]) ];
  var config_table_cols_right = [ shared.element('td',{id: 'order_item_edit_table_rcol_1'},'',config_table_rows[0]) ];
  
  config_table.find('td').each(function () {
    $(this).attr('valign','top');
  });
  
  
  // TaxProfiles
  var options = {
    name: 'tax_profiles',
    title: i18n.activerecord.models.tax_profile.one,
    append_to: dialog,
    selections: [
      {
        name: 'tax_profile',
        title: i18n.activerecord.models.tax_profile.one,
        options: (function () {
          var stys = {};
          for (var t in TaxProfiles) {
            var tax_profile = TaxProfiles[t];
            stys[tax_profile.id] = tax_profile.name;
          }
          return stys;
        })(),
        change: function () {
          var string = '/vendors/edit_field_on_child?id='+ Order.id +'&klass=Order&field=tax_profile_id&value=' + $(this).val();
          get(string, 'showOrderOptions->tax_profile', function () {
            //
          });
        },
        attributes: {name: i18n.activerecord.models.tax_profile.one},
        value: Order.tax_profile_id,
      }
    ]
  };
  var taxprofiles = shared.draw.select_option(options);
  taxprofiles.find('select').each(function () {make_select_widget($(this).attr('name'),$(this));});
  // end TaxProfiles
  
  // Proforma
  var options = {
    name: 'is_proforma',
    title: i18n.activerecord.attributes.is_proforma,
    value: Order.is_proforma,
    append_to: config_table_cols_right[0]
  };
  var callbacks = {change: function () {
    get("/vendors/edit_field_on_child?id=" + Order.id + "&klass=Order&field=toggle_is_proforma&value=x","ordersjs.js",function () {});
    }
  };
  var proforma_check = shared.draw.check_option(options,callbacks);
  
  // Buy Order
  var options = {
    name: 'is_buy_order',
    title: i18n.menu.buy_order,
    value: Order.buy_order,
    append_to: config_table_cols_left[0]
  };
  var callbacks = {change: function () {
    get("/vendors/edit_field_on_child?id=" + Order.id + "&klass=Order&field=toggle_buy_order&value=x","ordersjs.js",function () {});
  }
  };
  var buy_order_check = shared.draw.check_option(options,callbacks);
  // end Buy Order
  
  // salestype and countries
  var options = {
    name: 'sales_type_and_countries',
    title: i18n.menu.additional,
    append_to: dialog,
    selections: [
      // begin sale_types
      {
        name: 'sale_type',
        title: i18n.activerecord.models.sale_type.one,
        options: (function () {
          var stys = {};
          for (var t in SaleTypes) {
            var sale_type = SaleTypes[t];
            stys[sale_type.id] = sale_type.name;
          }
          return stys;
        })(),
        change: function () {
          var string = '/vendors/edit_field_on_child?id='+ Order.id +'&klass=Order&field=sale_type_id&value=' + $(this).val();
          get(string, 'showOrderOptions->sale_type', function () {
            //
          });
        },
        attributes: {name: i18n.activerecord.models.sale_type.one},
        value: Order.sale_type_id,
      }, 
      // end sale_types
      {
        name: 'origin_country',
        title: i18n.activerecord.models.country.one,
        options: (function () {
          var ctys = {};
          for (var t in Countries) {
            var country = Countries[t];
            ctys[country.id] = country.name;
          }
          return ctys;
        })(),
        change: function () {
          var string = '/vendors/edit_field_on_child?id='+ Order.id +'&klass=Order&field=origin_country_id&value=' + $(this).val();
          get(string, 'showOrderOptions->origin_country', function () {
            //
          });
        },
        attributes: {name: i18n.activerecord.models.country.one},
        value: Order.origin_country_id,
      }, 
      // end origin country
      {
        name: 'destination_country',
        title: i18n.activerecord.models.country.one,
        options: (function () {
          var ctys = {};
          for (var t in Countries) {
            var country = Countries[t];
            ctys[country.id] = country.name;
          }
          return ctys;
        })(),
        change: function () {
          var string = '/vendors/edit_field_on_child?id='+ Order.id +'&klass=Order&field=destination_country_id&value=' + $(this).val();
          get(string, 'showOrderOptions->destination_country', function () {
            //
          });
        },
        attributes: {name: i18n.activerecord.models.country.one},
        value: Order.destination_country_id,
      }, 
    ]
  };
  var additional = shared.draw.select_option(options);
  additional.find('select').each(function () {make_select_widget($(this).attr('name'),$(this));});
  shared.helpers.expand(dialog,0.60,'vertical');
  shared.helpers.center(dialog);
  dialog.show();
}


function detailedOrderItemMenu(event) {
  $('.item-menu-div').remove();
  var target = $(event.currentTarget).parent();
  var item = _get('item',target);
  var offset = $(event.currentTarget).offset();
  var title = shared.element('div',{id: 'order_item_edit_name'},'',$('body'));
  title.addClass('salor-dialog');
  title.offset(offset);
  title.css({padding: '3px',width: $(event.currentTarget).outerWidth() - 8, height: $(event.currentTarget).outerHeight(), 'border-bottom': 'none'});
  config = shared.element('div',{id: 'order_item_edit_config'},'',$('body'));
  config.addClass('salor-dialog');
  config.offset({top: offset.top + $(event.currentTarget).outerHeight() + 5, left: offset.left});
  config.css({width: $('#header').width() - 260, 'border-top':'none', 'min-height': '100px'});
  
  var dicon = $('<div id="item_menu_delete" class="oi-menu-icon"><img src="/images/icons/delete.svg" width="31px" height="32px" /></div>');
  dicon.click(function () {
    $.get('/orders/delete_order_item?id=' + item.id);
    title.remove();
    config.remove();
    $('#order_item_' + item.id).remove();
    focusInput($('#main_sku_field'));
  });
  title.append(dicon);
  
  var buyback = $('<div id="item_menu_buyback" class="oi-menu-icon"><img src="/images/icons/bill.svg" width="46px" height="28px" /></div>');
  buyback.addClass('pointer');
  buyback.click(function () {
    var string = '/vendors/edit_field_on_child?id=' +
    item.id +'&klass=OrderItem' +
    '&field=toggle_buyback'+
    '&value=undefined';
    $.get(string);
    focusInput($('#main_sku_field'));
  }).mouseup(function () {
    focusInput($('#main_sku_field'));
  });
  title.append(buyback);
  
  if (!Register.scale == '') {
    var wicon = $('<div id="item_menu_scale" class="oi-menu-icon"><img src="/images/icons/scale.svg" width="31px" height="32px" /></div>');
    wicon.click(function () {
      var string = '/vendors/edit_field_on_child?id=' +
      item.id +'&klass=OrderItem' +
      '&field=quantity'+
      '&value=' + Register.scale;
      $.get(string);
      focusInput($('#main_sku_field'));
    }).mouseup(function () {
      focusInput($('#main_sku_field'));
    });
    title.append(wicon);
  }
    
  var btn = $('<div id="item_menu_done" class="oi-menu-icon"><img src="/images/icons/okay.svg" width="31px" height="32px" /></div>');
  btn.click(function () {
    title.remove();
    config.remove();
    focusInput($('#main_sku_field'));
  }).mouseup(function () {
    focusInput($('#main_sku_field'));
  });
  title.append(btn);
  
  orderItemNameOption(config, item);
  
  var edit_item_hr = shared.element('h3',{id: 'order_item_options_h3'},i18n.menu.edit_item + '( ' + item.sku + ' )',config);
  edit_item_hr.click(function () {
    window.location = '/items/' + item.item_id + '/edit';
  });
  edit_item_hr.addClass('pointer no-select');
  edit_item_hr.css({'text-decoration': 'underline'});
  
  
  // ----------------------
  var config_table = shared.element('table',{id: 'order_item_edit_table', width: '90%', align:'center'},'',config);
  var config_table_rows = [ shared.element('tr',{id: 'order_item_edit_table_row_1'},'',config_table) ];
  
  var config_table_cols_left = [ shared.element('td',{id: 'order_item_edit_table_lcol_1'},'',config_table_rows[0]) ];
  var config_table_cols_center = [ shared.element('td',{id: 'order_item_edit_table_ccol_1'},'',config_table_rows[0]) ];
  var config_table_cols_right = [ shared.element('td',{id: 'order_item_edit_table_rcol_1'},'',config_table_rows[0]) ];
  
  // Edit ItemType
  shared.element('h4',{id: 'oi_item_type_h4'},i18n.activerecord.models.item_type.one,config_table_cols_left[0]);
  var item_type_select = shared.element('select',{id: 'oi_item_type_select'},'',config_table_cols_left[0]);
  item_type_select.on('change',function () {
    editItemAndOrderItem(item,'item_type_id',$(this).val());
    focusInput($('#main_sku_field'));
  });
  $.each(ItemTypes,function (i,item_type) {
    shared.element('option',{value: item_type.id},item_type.name,item_type_select);
  });
  item_type_select.val(item.item_type_id);
  make_select_widget('ItemType',item_type_select);
  
  // Edit TaxProfile
  shared.element('h4',{id: 'oi_tax_profile_h4'},i18n.activerecord.models.tax_profile.one,config_table_cols_center[0]);
  var tax_profile_select = shared.element('select',{id: 'oi_tax_profile_select'},'',config_table_cols_center[0]);
  tax_profile_select.on('change',function () {
    editItemAndOrderItem(item,'tax_profile_id',$(this).val());
    focusInput($('#main_sku_field'));
  });
  $.each(TaxProfiles,function (i,tax_profile) {
    shared.element('option',{value: tax_profile.id},tax_profile.name,tax_profile_select);
  });
  tax_profile_select.val(item.tax_profile_id);  // select current value
  make_select_widget('TaxProfile',tax_profile_select);
  
  
  // Edit Category
  shared.element('h4',{id: 'oi_category_h4'},i18n.activerecord.models.category.one,config_table_cols_right[0]);
  var category_select = shared.element('select',{id: 'oi_category_select'},'',config_table_cols_right[0]);
  category_select.on('change',function () {
    editItemAndOrderItem(item,'category_id',$(this).val());
    focusInput($('#main_sku_field'));
  });
  shared.element('option',{value: ''},'',category_select); // create empty option
  $.each(Categories,function (i,category) {
    var is_selected = category.id == 
    shared.element('option',{value: category.id},category.name,category_select);
  });
  category_select.val(item.category_id); // select current value

  make_select_widget('Category',category_select);
  var print_sticker = shared.element('div',{id: 'oi_print_sticker'},i18n.helpers.submit.print,config);
  print_sticker.mousedown(function () {
    print_url(Register.sticker_printer, '/items/labels', '&id=' + item.item_id + '&type=sticker&style=default')
  });
  print_sticker.addClass('button-confirm');
  shared.helpers.bottom_right(print_sticker,config,{top: -20,left: 5});
}

function editItemAndOrderItem(item,field,val,callback) {
  // This is supposed to be doubled, it edits both the orderitem and the item at the same go. Item should be first. OrderItem only after Item request has completed.
  var string = '/vendors/edit_field_on_child?id=' +
  item.item_id +'&klass=Item' +
  '&field=' + field +
  '&value=' + val;
  $.get(string,function() {
    var string = '/vendors/edit_field_on_child?id=' +
    item.id +'&klass=OrderItem' +
    '&field=' + field +
    '&value=' + val;
    $.get(string);
  });
}

function getBehaviorById(id) {
  var itid = 0;
  $.each(ItemTypes,function (i,item_type) {
    if (item_type.id == id) {
      itid = item_type.id;
    }
  });
  return itid;
}

function orderItemNameOption(append_to, item) {
  // name edit field
  var save_edit = function () {
    var id = '#option_order_item_name_input';
    var value = $(id).val();
    editItemAndOrderItem(item, 'name', value);
  };
  var callbacks = {
    click: save_edit,
    keypress: function(e) {
      if (e.which == 13) {
        save_edit();
      }
    }
  };
  var options = {
    name: 'order_item_name',
    title: i18n.activerecord.attributes.name,
    value: item.name,
    append_to: append_to
  };
  var opt = shared.draw.option(options, callbacks);
  
  // sku edit field
  var save_edit = function () {
    var id = '#option_order_item_sku_input';
    var value = $(id).val();
    editItemAndOrderItem(item, 'sku', value);
  };
  var callbacks = {
    click: save_edit,
    keypress: function(e) {
      if (e.which == 13) {
        save_edit();
      }
    }
  };
  var options = {
    name: 'order_item_sku',
    title: i18n.activerecord.attributes.sku,
    value: item.sku,
    append_to: append_to
  };
  var opt = shared.draw.option(options, callbacks);
}

function getOrderItemId(item) {
  var id = 'order-item-' + item.id;
  return id;
}

function highlight(elem) {
  if (!elem.hasClass("pos-highlight")) {
    elem.addClass("pos-highlight");
  }
}

function refund_item(id) {
  refund_payment_method_id = $('#refund_payment_method').val();
  window.location = '/orders/refund_item?id=' + id + '&pm=' + refund_payment_method_id;
  if (PaymentMethodObjects[refund_payment_method_id].cash == true) {
    quick_open_drawer()
  }
}

function clearOrder() {
  $.get('/orders/clear?order_id=' + Order.id);
}

