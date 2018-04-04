sr.fn.inventory = {
  
  setup: function() {
    $("#inventory_sku").on('click', function() {
      $(this).select();
    });
    $("#inventory_sku").keyup(function(e) {
      if (e.which == 13) {
        sr.fn.inventory.fetch_json($(this).val());
      }
    });
    $("#inventory_quantity").keyup(function(e) {
      if (e.which == 13) {
        sr.fn.inventory.update_real_quantity($('#inventory_item_sku').html(), $(this).val());
      }
    });
  },
  
  fetch_json: function(sku) {
    $.ajax({
      url: "/inventory_reports/inventory_json?sku=" + $("#inventory_sku").val(),
      dataType: 'json',
      success: sr.fn.inventory.fetch_json_success
    });
    
  },
  
  fetch_json_success: function(data, status) {
    if (data != null) {
      $('#inventory_sku').val('');
      $('#inventory_item_name').html(data.name);
      $('#inventory_item_sku').html(data.sku);
      $('#inventory_item_current_quantity').html(data.real_quantity);
      $('#inventory_quantity').focus();
    } else {
      $('#inventory_item_name').html("---");
      $('#inventory_item_sku').html("---");
      $('#inventory_item_current_quantity').html("---");
      $('#inventory_sku').focus();
    }
  },
  
  update_real_quantity: function(sku, quantity) {
    $.ajax({
      url: "/inventory_reports/update_real_quantity?sku=" + sku + "&real_quantity=" + quantity,
      dataType: 'json',
      success: sr.fn.inventory.update_real_quantity_success
    });
  },
  
  update_real_quantity_success: function(data, status) {
    if (data.status == 'success') {
      $('#inventory_quantity').val('');
      $('#inventory_sku').val('');
      $('#inventory_item_name').html('&nbsp;');
      $('#inventory_item_sku').html('&nbsp;');
      $('#inventory_item_current_quantity').html('&nbsp;');
      $('#inventory_sku').focus();
      $('#inventory_msg').html('✓');
      $('#inventory_msg').fadeIn(1000, function() {
        $('#inventory_msg').fadeOut(3000);
      });
    }
  },
  
  create_inventory_report_confirm_dialog: function() {
    var contents = i18n.are_you_sure;
    var dialog = shared.draw.dialog('','create_inventory_report_dialog', contents);
    var loader = shared.draw.loading(true,null,dialog);
    var okbutton = shared.create.dialog_button(i18n.menu.ok, function() {
      loader.show();
      sr.fn.debug.ajaxLog({
        action_taken:'confirmed_create_inventory_report_dialog'
      });
      window.location = '/inventory_reports/create_inventory_report';
    });
    dialog.append(okbutton);
  }
}
  