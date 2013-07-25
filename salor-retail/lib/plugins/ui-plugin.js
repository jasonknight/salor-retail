(function () {
  Salor.log_action("Initializing Plugin ui-plugin.js");
  var plugin = {
    my_ui_plugin: {
      salor_icon_filter: function (icon) {
        Salor.log_action('deciding...');
        if (icon == 'plugin') {
          return 'vendor';
        }
        return icon;
      }
    }
  };

  Salor.add_filter('salor_icon','my_ui_plugin.salor_icon_filter');
  return plugin;
})();