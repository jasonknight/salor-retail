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
