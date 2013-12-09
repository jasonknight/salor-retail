Salor.log_action("Initializing Plugin WCJSON API");
// Use plugins. inside your functions, but don't use plugins.
// when registering a handler, as all handlers, hooks, filters
// are already relative to plugins.
plugins.wcjsonapi_sr = {
  conf: {},
  item_list_columns: function (cols) {
    // When we return strings, they need to be localized,
    // an entry for each supported language if that key isn't
    // already in the translation files.
    cols.push({name: 'wcjsonapi_sr_send_to_wp','en': "Send to WP"});
    return cols;
  },
  item_list_column: function (params) {
    var item = params.item;
    var col = params.column;
    Salor.log_action("Params are: " + JSON.stringify(params));
    if ( col['name'] == 'wcjsonapi_sr_send_to_wp') {
      Salor.log_action("col name was correct");
      params.column = '<img src="' + URLS.images + '/wcjsonapi_sr/wordpress_logo.svg" height="16"/>';
    } else {
      Salor.log_action("was not correct");
    }
    return params;
  }
}
/*
  This is optional, in case you want to save
*/
for (key in __plugin__) {
  plugins.wcjsonapi_sr.conf[key] = __plugin__[key];
}
Salor.add_filter('item_list_columns','wcjsonapi_sr.item_list_columns');
Salor.add_filter('item_list_column','wcjsonapi_sr.item_list_column');


