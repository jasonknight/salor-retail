/**
  WooCommerce JSON API Example Plugin for Actions

  Copyright 2013-2014 Red(E) Tools Ltd.
  Author: Jason Knight
*/

/* User Editable Region is Here */
var URL             = 'http://woo.localhost/c6db13944977ac5f7a8305bbfb06fd6a/';
var TOKEN           = '1234';
/* End of Editable Region */

api.log_action("Beginning " + api.plugin_name + " for action " + api.action );
api.log_action("Params: " + JSON.stringify(api.params));

var params = {
  action: 'woocommerce_json_api',
  arguments: {
    token: TOKEN,
  }
};

function get_product_by_sku(sku) {
  params.proc = "get_products";
  params.arguments.page = 1;
  params.arguments.per_page = 1;
  params.arguments.skus = [sku];
  api.log_action(JSON.stringify(params));
  var body = api.post(URL, {'Content-Type': 'application/json'}, JSON.stringify(params));
  var result = JSON.parse(body);
  var product = result.payload[0];
  if (product && product.name && product.price) {
    var attrs = {
      price: product.price,
      name: product.name,
    }
    api.update_attributes(attrs);
  }
}

if (api.action == 'on_sku_not_found') {
  get_product_by_sku(api.params['sku']);
}
