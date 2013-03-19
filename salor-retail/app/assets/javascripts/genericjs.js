function updateDrawer(obj) {
  $('.pos-cash-register-amount').html(toCurrency(obj.amount));
  $('.eod-drawer-total').html(toCurrency(obj.amount));
  $('#header_drawer_amount').html(toCurrency(obj.amount));
}
function positionSearchInput() {
  var elem = $("#generic_search");
  if (elem.length == 0) {
    return;
  }
  shared.helpers.top_right(elem,$('body'),{left: -20,top: 0});
  var off = elem.offset();
  off.top = 0;
  elem.offset(off);
  elem.css({'z-index': 1005});
  var elem = $(".generic-search-button");
  shared.helpers.bottom_right(elem,$("#generic_search_input"),{left: 45,top:-5});
}
