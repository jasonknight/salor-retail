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
    window.location = "/employees/login?" + p.join("&");
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
        var dicon = $('<div id="item_menu_delete" class="oi-menu-icon"><img src="/images/icons/delete_32.png" /></div>');
        dicon.mousedown(function () {
            $('.' + base_id).remove();
            get('/orders/delete_order_item?id=' + item.id, filename);
            menu.remove();
            //setScrollerState();
            focusInput($('#keyboard_input'));
        });
        menu.append(dicon);
        
        var buyback = $('<div id="item_menu_buyback" class="oi-menu-icon"><img src="/images/icons/money_32.png" /></div>');
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
          var wicon = $('<div id="item_menu_scale" class="oi-menu-icon"><img src="/images/icons/weight_32.png" /></div>');
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

        var btn = $('<div id="item_menu_done" class="oi-menu-icon"><img src="/images/icons/tick_32.png" /></div>');
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
    if(Register.pole_display == "") {
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
window.retail = {container: $(window)};
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
  config.css({width: $('#header').width() - 160, 'border-top':'none', 'min-height': '100px'});
  
  var name = orderItemNameOption(config,item,event.currentTarget.textContent);
  name.find('input').css({width: $('#header').width() * 0.50});
  
  var dicon = $('<div id="item_menu_delete" class="oi-menu-icon"><img src="/images/icons/delete_32.png" /></div>');
  dicon.mousedown(function () {
    $.get('/orders/delete_order_item?id=' + item.id);
    title.remove();
    config.remove();
    $('#order_item_' + item.id).remove();
    focusInput($('#keyboard_input'));
  });
  title.append(dicon);
  
  var buyback = $('<div id="item_menu_buyback" class="oi-menu-icon"><img src="/images/icons/money_32.png" /></div>');
  buyback.addClass('pointer');
  buyback.mousedown(function () {
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
    var wicon = $('<div id="item_menu_scale" class="oi-menu-icon"><img src="/images/icons/weight_32.png" /></div>');
    wicon.mousedown(function () {
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
    
    var btn = $('<div id="item_menu_done" class="oi-menu-icon"><img src="/images/icons/tick_32.png" /></div>');
    btn.mousedown(function () {
      title.remove();
      config.remove();
      focusInput($('#keyboard_input'));
    }).mouseup(function () {
      focusInput($('#keyboard_input'));
    });
    title.append(btn);
    
    var edit_item_hr = shared.element('h3',{id: 'order_item_options_h3'},i18n.menu.edit_item + '( ' + item.sku + ' )',config);
    edit_item_hr.mousedown(function () {
      window.location = '/items/' + item.item_id + '/edit';
    });
    edit_item_hr.addClass('pointer no-select');
    edit_item_hr.css({'text-decoration': 'underline'});
    
    var config_table = shared.element('table',{id: 'order_item_edit_table', width: '90%', align:'center'},'',config);
    var config_table_rows = [ shared.element('tr',{id: 'order_item_edit_table_row_1'},'',config_table) ];
    
    var config_table_cols_left = [ shared.element('td',{id: 'order_item_edit_table_lcol_1'},'',config_table_rows[0]) ];
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
