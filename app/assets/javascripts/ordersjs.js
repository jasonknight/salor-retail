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
    var oid = $('.order-id').html();
    var cid = Meta['cash_register_id'];
    var p = ["code=" + sku, "order_id=" +oid, "cash_register_id=" + cid, "redirect="+ escape("/orders/new?cash_register_id=1&order_id=" + oid)];
    window.location = "/employees/login?" + p.join("&");
    return;
  }
  var user_line = "&user_id=" + User.id + "&user_type=" + User.type;
  get('/orders/add_item_ajax?order_id='+$('.order-id').html()+'&sku=' + sku + user_line + additional_params, filename);
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
        $('.item-menu-div').remove();
        var menu = $("<div class='item-menu-div'></div>");
        $('body').append(menu);
        menu.css({position: 'absolute', left: event.pageX, top: event.pageY});
        var dicon = $('<div class="oi-menu-icon"><img src="/images/icons/delete_32.png" /></div>');
        dicon.mousedown(function () {
            $('.' + base_id).remove();
            get('/orders/delete_order_item?id=' + item.id, filename);
            menu.remove();
            //setScrollerState();
            focusInput($('#keyboard_input'));
        });
        menu.append(dicon);
        
        var buyback = $('<div class="oi-menu-icon"><img src="/images/icons/money_32.png" /></div>');
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
          var wicon = $('<div class="oi-menu-icon"><img src="/images/icons/weight_32.png" /></div>');
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

        var btn = $('<div class="oi-menu-icon"><img src="/images/icons/tick_32.png" /></div>');
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
