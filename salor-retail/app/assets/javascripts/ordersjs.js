


function getByCardAmount() {
  var val = 0;
  $(".payment-method").each(function () {
    var id = $(this).attr("id").replace("type","amount");
    if ($(this).val() == "ByCard") {
        val = $('#' + id).val();
    }
  });
  return val;
}


function add_item(sku, additional_params) {
  if (sku.match(/^31\d{8}.{1,2}$/)) {
    var oid = Order.id;
    var cid = Meta['cash_register_id'];
    var p = ["code=" + sku, "order_id=" +oid, "cash_register_id=" + cid, "redirect="+ escape("/orders/new?cash_register_id=1&order_id=" + oid)];
    window.location = "/users/login?" + p.join("&");
    return;
  }
  var user_line = "&user_id=" + User.id + "&user_type=" + User.type;
  get('/orders/add_item_ajax?order_id=' + Order.id + '&sku=' + sku + user_line + additional_params, filename);
  $('#keyboard_input').val('');
}

function void_item(id) {
  get('/orders/split_order_item?id=' + id, filename, function () {
    window.location.reload();
  });
}

function update_order_items() {
  return;
  get('/orders/update_order_items?ajax=true', filename, function (data) {
    $('#scroll_content').html(data);
    $('#order_items_table tr').removeClass('even')
    $('#order_items_table tr:even').addClass('even');
    $('.pos-lock-small').each(function () {
      make_toggle($(this));
    });
  });
}

function editLastAddedItem() {
  var itemid = $(".pos-table-left-column-items").children(":first").attr('item_id');
  if (itemid) {
    var string = '/items/' + itemid + '/edit'
    window.location = string;
  }
}

function update_pos_display() {
  return;
  //get('/orders/update_pos_display?ajax=true', filename);
}

//function refund_item(id) {
//  get('/vendors/toggle?' +
//    'field=toggle_refund' +
//    '&klass=OrderItem' +
//    '&value=true' +
//    '&model_id=' + id,
//  filename,
//  function () {
//    window.location.reload();
//  }
//);
//}

/* FROM views/orders/new.html.erb */
function makeItemMenu(item) {
  try {

    var base_id = getOrderItemId(item);
    var e = $('.' + base_id + '-name');
    //This is because if the SKU gets too big, it messes up the screen
    //e.html(e.html().substr(0,7));
    e.html(e.html());

    e.unbind();
    e.mousedown(function (event) {
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
            $('.' + base_id).remove();
            get('/orders/delete_order_item?id=' + item.id, filename);
            menu.remove();
            //setScrollerState();
            focusInput($('#keyboard_input'));
        });
        menu.append(dicon);
        
        var buyback = $('<div id="item_menu_buyback" class="oi-menu-icon"><img src="/images/icons/bill.svg" width="46px" height="28px" /></div>');
        buyback.addClass('pointer');
        buyback.mousedown(function () {
            var string = '/vendors/toggle?model_id=' +
                          item.id +'&klass=OrderItem' +
                          '&field=toggle_buyback'+
                          '&value=undefined';
                          get(string, filename);
                          menu.remove();
                          focusInput($('#keyboard_input'));
        }).mouseup(function () {
          focusInput($('#keyboard_input'));
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
              focusInput($('#keyboard_input'));
          }).mouseup(function () {
            focusInput($('#keyboard_input'));
          });

          menu.append(wicon);
        } // end  if (!Register.scale == '') {

        var btn = $('<div id="item_menu_done" class="oi-menu-icon"><img src="/images/icons/okay.svg" width="31px" height="32px" /></div>');
        btn.mousedown(function () {
            menu.remove();
            focusInput($('#keyboard_input'));
        }).mouseup(function () {
          focusInput($('#keyboard_input'));
        });
        menu.append(btn);
    });

  } catch (err) {
    //console.log(err);
  }
}

function updateCustomerView(item,order_id) {
  if (typeof(Salor) != 'undefined') {
    if( useMimo() ) {
      Salor.mimoRefresh(Conf.url+"/orders/"+order_id+"/customer_display",800,480);
    } else {
      if (item == false) {
        showOrderTotalOnPoleDisplay(); 
      } else {
        output = format_pole(item['name'],item['price'],item['quantity'],item['weight_metric'],item['total']); 
        Salor.poleDancer(Register.pole_display, output );
      }
    }
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
      get(string, 'showOrderOptions', function () {
        update_order_items();
        update_pos_display();
      });
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
  // TaxFree
  var callbacks = {change: function () {
      get("/vendors/toggle?model_id=" + Order.id + "&klass=Order&field=toggle_tax_free&value=x","ordersjs.js",function () {});
    }
  };
  var options = {
    name: 'tax_free',
    title: i18n.activerecord.attributes.tax_free,
    value: Order.tax_free,
    append_to: config_table_cols_left[0]
  };
  var tax_free_check = shared.draw.check_option(options,callbacks);
  // end TaxFree
  
  // Proforma
  var options = {
    name: 'is_proforma',
    title: i18n.activerecord.attributes.is_proforma,
    value: Order.is_proforma,
    append_to: config_table_cols_right[0]
  };
  var callbacks = {change: function () {
    get("/vendors/toggle?model_id=" + Order.id + "&klass=Order&field=toggle_is_proforma&value=x","ordersjs.js",function () {});
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
    get("/vendors/toggle?model_id=" + Order.id + "&klass=Order&field=toggle_buy_order&value=x","ordersjs.js",function () {});
  }
  };
  var buy_order_check = shared.draw.check_option(options,callbacks);
  // end Proforma
  
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
  
  var name = orderItemNameOption(config,item,event.currentTarget.textContent);
  name.find('input').css({width: $('#header').width() * 0.50});
  
  var dicon = $('<div id="item_menu_delete" class="oi-menu-icon"><img src="/images/icons/delete.svg" width="31px" height="32px" /></div>');
  dicon.click(function () {
    $.get('/orders/delete_order_item?id=' + item.id);
    title.remove();
    config.remove();
    $('#order_item_' + item.id).remove();
    focusInput($('#keyboard_input'));
  });
  title.append(dicon);
  
  var buyback = $('<div id="item_menu_buyback" class="oi-menu-icon"><img src="/images/icons/bill.svg" width="46px" height="28px" /></div>');
  buyback.addClass('pointer');
  buyback.click(function () {
    var string = '/vendors/toggle?model_id=' +
    item.id +'&klass=OrderItem' +
    '&field=toggle_buyback'+
    '&value=undefined';
    $.get(string);
    focusInput($('#keyboard_input'));
  }).mouseup(function () {
    focusInput($('#keyboard_input'));
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
      focusInput($('#keyboard_input'));
    }).mouseup(function () {
      focusInput($('#keyboard_input'));
    });
    title.append(wicon);
  } // end  if (!Register.scale == '') {
    
    var btn = $('<div id="item_menu_done" class="oi-menu-icon"><img src="/images/icons/okay.svg" width="31px" height="32px" /></div>');
    btn.click(function () {
      title.remove();
      config.remove();
      focusInput($('#keyboard_input'));
    }).mouseup(function () {
      focusInput($('#keyboard_input'));
    });
    title.append(btn);
    
    var edit_item_hr = shared.element('h3',{id: 'order_item_options_h3'},i18n.menu.edit_item + '( ' + item.sku + ' )',config);
    edit_item_hr.click(function () {
      window.location = '/items/' + item.item_id + '/edit';
    });
    edit_item_hr.addClass('pointer no-select');
    edit_item_hr.css({'text-decoration': 'underline'});
    
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
      focusInput($('#keyboard_input'));
    });
    $.each(ItemTypes,function (i,item_type) {
      shared.element('option',{value: item_type.id},item_type.name,item_type_select);
    });
    make_select_widget('Item Type',item_type_select);
    
    // Edit ItemType
    shared.element('h4',{id: 'oi_tax_profile_h4'},i18n.activerecord.models.tax_profile.one,config_table_cols_center[0]);
    var tax_profile_select = shared.element('select',{id: 'oi_tax_profile_select'},'',config_table_cols_center[0]);
    tax_profile_select.on('change',function () {
      editItemAndOrderItem(item,'tax_profile_id',$(this).val());
      focusInput($('#keyboard_input'));
    });
    $.each(TaxProfiles,function (i,tax_profile) {
      shared.element('option',{value: tax_profile.id},tax_profile.name,tax_profile_select);
    });
    make_select_widget('Item Type',tax_profile_select);
    
    
    // Edit Category
    shared.element('h4',{id: 'oi_category_h4'},i18n.activerecord.models.category.one,config_table_cols_right[0]);
    var category_select = shared.element('select',{id: 'oi_category_select'},'',config_table_cols_right[0]);
    category_select.on('change',function () {
      editItemAndOrderItem(item,'category_id',$(this).val());
      focusInput($('#keyboard_input'));
    });
    $.each(Categories,function (i,category) {
      shared.element('option',{value: category.id},category.name,category_select);
    });
    make_select_widget('Item Type',category_select);
    var print_sticker = shared.element('div',{id: 'oi_print_sticker'},i18n.helpers.submit.print,config);
    print_sticker.mousedown(function () {
      print_url(Register.sticker_printer, '/items/labels', '&id=' + item.item_id + '&type=sticker&style=default')
    });
    print_sticker.addClass('button-confirm');
    shared.helpers.bottom_right(print_sticker,config,{top: -20,left: 5});
}
function editItemAndOrderItem(item,field,val,callback) {
  var string = '/vendors/edit_field_on_child?id=' +
  item.id +'&klass=OrderItem' +
  '&field=' + field +
  '&value=' + val;
  $.get(string);
  // This is supposed to be doubled, it edits both the orderitem and the item at the same go.
  string = '/vendors/edit_field_on_child?id=' +
  item.item_id +'&klass=Item' +
  '&field=' + field +
  '&value=' + val;
  $.get(string,callback);
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
function orderItemNameOption(append_to,item,initvalue) {
  var save_edit = function () {
    var id = '#option_order_item_name_input';
    var value = $(id).val();
    var string = '/vendors/edit_field_on_child?id='+ item.item_id +'&klass=Item&field=name&value=' + value;
    $.get(string,  function () {
      $("#order_item_" + item.id).find('.pos-item-name').html(value);      
      update_pos_display();
    });
  };
  var callbacks = {
    click: save_edit,
    focus: function () {
      var inp = $(this);
      setTimeout(function () {
        inp.select();
      }, 170);
    }
  };
  var options = {
    name: 'order_item_name',
    title: i18n.activerecord.attributes.name,
    value: initvalue,
    append_to: append_to
  };
  var opt = shared.draw.option(options,callbacks);
  opt.find('input').on('blur',save_edit);
  return opt;
}

/*
 *
 * From Orders/New
 *
 */


function getOrderItemId(item) {
  var id = 'order-item-' + item.id;
  return id;
}

function format_pole(name,price,quantity,weight_metric,total) {
  if (weight_metric == null) { weight_metric = '' };
  pole_name     = (name.substring(0,14) + '                ').substring(0,14);
  pole_price    = sprintf("%6.2f",price);
  pole_quantity = (quantity + ' ' + weight_metric + '                            ').substring(0,10);
  pole_total    = i18n.number.currency.format.friendly_unit + sprintf(" %6.2f",total);
  return pole_name + pole_price + pole_quantity + pole_total;
}

function updatePosItem(item) {
  
  var base_id = getOrderItemId(item);
  _set('item',item,$('#order_item_' + item.id));
  //item['price'] = item['price'] - item['discount_amount'];
  item['coupon_amount'] = item['coupon_amount'] + item['discount_amount'];
  if (Register.hide_discounts) {
    var attrs = ['name','quantity','price','total'];
  } else {
    var attrs = ['name','quantity','price','coupon_amount','rebate','total'];
  }
  for (var i = 0; i < attrs.length; i++) {
    var key = attrs[i];
    var id = '.' + base_id + '-' + key;
    if ( (item['discount_amount'] < 0 || item['coupon_amount'] < 0) && key == 'coupon_amount') { $(id).addClass('discount_applied'); };
    if (key == 'price' || key == 'coupon_amount' || key == 'total' || key == 'rebate') {
      if ( (item['behavior'] == 'coupon' && item['coupon_type'] == 1 ) || key == 'rebate') {
        $(id).html(toPercent(item[key]));
      } else {
        $(id).html(toCurrency(item[key]));
      }
    } else {
      if (key == 'sku') {
        //item[key] = item[key].substr(0,8);
        item[key] = item[key];
      }
      $(id).html(item[key]);
    }
    if (item['is_buyback'] & highlightAttrs.indexOf(key) != -1) {
      highlight($(id));
    } else {
      $(id).removeClass("pos-highlight");
    }
  }
  makeItemMenu(item);
  if (item["must_change_price"] == true) {
    var id = '.' + base_id + '-price';
    var price = toFloat($(id).html());
    if (price == 0) {
      $(id).trigger('click');
      setTimeout( function () {
        if (IS_APPLE_DEVICE) {
          $('.ui-keyboard-preview').val("");
        }
        $(".ui-keyboard-preview").select();
      },100);
        
    }
  }
}

function addPosItem(item) {
  var row = $("<div id='order_item_"+item.id+"' model_id='"+item.id+"' item_id='"+item.item_id+"' ></div>");
  var base_id = getOrderItemId(item);
  
  row.addClass(base_id);
  //item['price'] = item['price'] + item['discount_amount'];
  item['coupon_amount'] = item['coupon_amount'] + item['discount_amount'];
  $('.pos-table-left-column-items').prepend(row);
  _set('item',item,row);
  var attrs;
  if (Register.hide_discounts == true) {
    attrs = ['name','quantity','price','total'];
  } else {
    attrs = ['name','quantity','price','coupon_amount','rebate','total','tax_profile_amount'];
  }
  for (var i = 0; i < attrs.length; i++) {
    var attr = attrs[i];
    var col = $("<div class='table-cell' id='"+ base_id + "_" + attr + "_inp'></div>");
    // those need number formatting
    if (attr == 'price' || attr == 'coupon_amount' || attr == 'total' || attr == 'rebate' || attr == 'tax_profile_amount') {
      if (item["action_applied"] == true && attr != 'total' && attr != 'tax_profile_amount') {
        col.addClass("pos-action-applied");
      }
      
      // those need special formatting
      if ( (item['behavior'] == 'coupon' && item['coupon_type'] == 1 ) || attr == 'rebate' || attr == 'tax_profile_amount' ) {
        col.html(toPercent(item[attr]));
      } else {
        col.html(toCurrency(item[attr]));
      }
    } else {
      col.html(item[attr]);
    }
    col.addClass('table-column pos-item-attr');
    col.addClass(base_id + '-' + attr + ' pos-item-' + attr);
    if ( (item['discount_amount'] < 0 || item['coupon_amount'] < 0) && attr == 'coupon_amount') { col.addClass('discount_applied'); };
    if ( attr == 'tax_profile_amount') {
      //MF: these percentages are hard coded for Austria since I don't have a quick possibility to fetch a TaxProfile color. Items having right taxes is important for the Fisc, so we give the users the opportunity to see them and change if necessary.
      if (item['tax_profile_amount'] == 0) {
        col.css('backgroundColor', '#9a809e');
      } else if ( item['tax_profile_amount'] == 10 ) {
        col.css('backgroundColor', '#7a607e');
      } else if (item['tax_profile_amount'] == 20 ) {
        col.css('backgroundColor', '#7D5285');
      };
    };
    if (attr == 'sku' || attr == 'coupon_amount') {
      
    } else {
      if (attr == 'name') {
        col.attr('model_id',item.item_id);
        col.attr('klass','Item');
      } else {
        col.attr('model_id',item.id);
        col.attr('klass','OrderItem');
      }
      col.attr('field',attr);
      if (attr == "price" || attr == "rebate" || attr == "name" || attr == "tax_profile_amount") {
        if (
              (User.role_cache.indexOf('change_prices') != -1) || 
              (User.role_cache.indexOf("manager") != -1) ||
              (item["must_change_price"] == true)
           ) {
              make_in_place_edit(col);
              col.addClass('editme pointer no-select');
          }
      } else if (attr == "quantity") {
        make_in_place_edit(col);
        col.addClass('editme pointer no-select');
      }
    }
    if (attr == 'quantity') {
      //MF: Why is this special in editing? Why not use just class editme for editing?
      if (Register.show_plus_minus == true) {
        var up = td().removeClass('jtable-cell').addClass('table-cell');
        
        up.mousedown(function () {
          var v = toFloat($('.' + base_id + '-quantity').html()) + 1;
          var string = '/vendors/edit_field_on_child?id=' +
          item.id +'&klass=OrderItem' +
          '&field=quantity'+
          '&value=' + v;
          get(string, filename);
          focusInput($('#keyboard_input'));
        });
          up.html("<div><img src=\"/images/icons/up.svg\" height='32' />");
          up.addClass('pointer quantity-button');
          row.append(up);
      }
      row.append(col);
      if (Register.show_plus_minus == true) {
        var d = td().removeClass('jtable-cell').addClass('table-cell');
        d.mousedown(function () {
          var v = toFloat($('.' + base_id + '-quantity').html()) - 1;
          var string = '/vendors/edit_field_on_child?id=' +
          item.id +'&klass=OrderItem' +
          '&field=quantity'+
          '&value=' + v;
          get(string, filename);
          focusInput($('#keyboard_input'));
        });
          d.html("<div><img src=\"/images/icons/down.svg\" height='32' />");
          d.addClass('pointer quantity-button');
          row.append(d);
      }
    } else {
      row.append(col);
    }
    if (item['is_buyback'] && highlightAttrs.indexOf(attr) != -1) {
      highlight(col);
    }
  }
  makeItemMenu(item);
  //setScrollerState();
  if (item["must_change_price"] == true) {
    var id = '.' + base_id + '-price';
    var price = toFloat($(id).html());
    if (price == 0) {
      $(id).trigger('click');
      setTimeout( function () {
        if (IS_APPLE_DEVICE) {
          $('.ui-keyboard-preview').val("");
        }
        $(".ui-keyboard-preview").select();
      },100);
    }
  }
  if(item['quantity']==0 && item['weigh_compulsory']) { weigh_last_item(); }
  
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
  if (order.customer) { showCustomer(order.customer,order.loyalty_card); }
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

function showCustomer(obj,lc) {
  return;
  var e = $('.pos-customer');
  e.html('');
  var name = $('<div><span class="customer_name"></span></div>');
  name.html(obj.first_name + ' ' + obj.last_name);
  var row = $('<div></div>');
  row.append(name);
  row.append('<span class=""><%= I18n.t("activerecord.attributes.points") %></span>');
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
  row.append('<span class=""><%= I18n.t("activerecord.attributes.lc_points") %></span>');
  var col = $('<span id="pos-order-points" class="order-points">0</span>');
  col.attr('model_id',Order.id);
  col.attr('klass','Order');
  col.attr('field','lc_points');
  col.addClass('editme');
  make_in_place_edit(col);
  row.append(col);
  e.html(row);
  if (!e.hasClass('shown')) {
    e.hide();
  }
  if (!$('.pos-customer').hasClass('shown')) {
    showHideCustomerOrRebate();
  }
}

function highlight(elem) {
  if (!elem.hasClass("pos-highlight")) {
    elem.addClass("pos-highlight");
  }
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
