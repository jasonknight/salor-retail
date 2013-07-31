var shippers = {
  update_confirm_dialog: function() {
    var contents = i18n.are_you_sure;
    var dialog = shared.draw.dialog('','update_shipper_dialog', contents);
    var loader = shared.draw.loading(true,null,dialog);
    var okbutton = shared.create.dialog_button(i18n.menu.ok, function() {
      loader.show();
      ajax_log({
        action_taken:'confirmed_update_shipper_dialog'
      });
      window.location = '/shippers/update_wholesaler';
    });
    dialog.append(okbutton);
  }
};