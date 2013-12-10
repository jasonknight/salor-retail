Salor.log_action("Initializing Plugin vendors_show_plugin");
// Use plugins. inside your functions, but don't use plugins.
// when registering a handler, as all handlers, hooks, filters
// are already relative to plugins.
plugins.vendors_show_plugin = {
  conf: {},
  after_hook: function (icon) {
    Salor.log_action("Hello from " + plugins.vendors_show_plugin.conf.name);
    var div = Salor.render_partial('vendors/show_list_entry',{
      mouseclick: 'window.location = "/countries"',
      href: '/countries',
      icon_name: 'plugin',
      translation: 'activerecord.models.plugin.other'
    });
    return div;
  }
}
/*
  This is optional, in case you want to save
*/
for (key in __plugin__) {
  plugins.vendors_show_plugin.conf[key] = __plugin__[key];
}
Salor.add_hook('after_vendors_show_list','vendors_show_plugin.after_hook');


