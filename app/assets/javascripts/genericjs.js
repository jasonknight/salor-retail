// DOCUMENT READY FUNCTIONS
var focuseKeyboardInput = false;
var calledFrom = 'TopOfAppJS';
var filename = "_application_js.html.erb";

$(function () {
  try {
    $('.click-help').click(function (event) {
      var url = $(this).attr('url');
      var offset = {'top' : event.pageY, 'left' : event.pageX, 'position' : 'absolute'}
      $('.help').css(offset);
      get(url, 'application.html.erb');
    });
  } catch (err) {
    txt="There was an error on this page application.html.erb.\n\n";
    txt+="Error description: " + err.description + "\n\n";
    txt+="Click OK to continue.\n\n";
    alert(txt);
  }

  if (typeof(Salor) != 'undefined' && $Register.pole_display != '') {
    Salor.poleDancer($Register.pole_display, '     S A L O R      Next Generation POS' );
  }

  jQuery.expr[':'].focus = function( elem ) {
    return elem === document.activeElement && ( elem.type || elem.href );
  };

  $(".action-button").each(function () {
    make_action_button($(this));
  });

  $('#order_items_table tr:even').addClass('even');
  $('.stripe-me tr:even').addClass('even');
  $('.stripe-me2:even').addClass('even');
  $('div.stripe-me > div.table-row:even').addClass('even');
  $('#generic_search_input').val('');



  $(document).keypress(function(event){                 
    var keyCode = (event.which) ? event.which : event.keyCode;
    if (keypressMap[keyCode]) {
      var func = keypressMap[keyCode];
      func(event);
      var cf = $('.salor-focused');
      if (cf.hasClass('inplaceeditinput') && cf.val() != '') {
        $('#inplaceeditsave').trigger('click');
        handled = true;
      } else if (cf.hasClass('shipment-items-input') && cf.hasClass('attr-input-sku')) {
        cf.trigger('blur');
        handled = true;
      } else if (cf.attr('id') == 'search_keywords') {
        search();
        event.preventDefault();
        return false;
      }
      if ($('#keyboard_input').val()) {
        if (handleKeyboardEnter) {
          //keypad_callbacks['Enter'].call(this);
          add_item($('#keyboard_input').val(),'');
          handled = true;
        } else {
          event.preventDefault();
          return false;
        }
      } else {
        //we aren't on the pos screen, so we should have some generic behaviors
        if (params.controller == "shippers") {
          handled = true;
        }
        focusInput($('#keyboard_input'));
      }
      if ($('#generic_search_input').length != 0 && $('#generic_search_input').val() != '') {
        generic_search();
        handled = true;
        return false;
      }
      if (isEditItem()) {
        handled = true;
        return false;
      }
      if (isEditItemLocation()) {
        update_location_submit();
        handled = true;
        return false;
      }
      if (isEditItemRealQuantity()) {
        update_real_quantity_submit();
        handled = true;
        return false;
      }
      if (isShipmentsEdit()) {
        shipments_edit_handler(event.target);
        handled = true;
        return false;
      }
      if (isDiscountsEdit() || isCustomersEdit()) {
        handled = true;
        return false;
      }
      if (handled == true) {
        event.preventDefault();
        return false;
      } else {
        return true;
      }
    }
  });

  focusInput($('#generic_search_input'));

  // FOR FANCY CHECKBOXES:
  $('input:checkbox:not([safari])').checkbox();
  $('input[safari]:checkbox').checkbox({cls:'jquery-safari-checkbox'});
  $('input:radio').checkbox();

  var ready_ran = false;
  if (ready_ran == false) {
    $('.toggle').each(function () {
        make_toggle($(this));
    });
    $('.dt-tag-button').each(function () { make_dt_button($(this));});
    $(".header-list").children("li").each(function () {
        var div = $(this).children('div');
        if (!div.hasClass('no-touchy')) {
          var link = div.children("a");
          if (link.hasClass('speedlink-done')) {
              return;
          }
          
          $(this).mousedown(function () {
              window.location = link.attr('href');
          });
          
          link.addClass('speedlink-done');
        }
    });
    $('.editme').each(function () {
      make_in_place_edit($(this));                  
    });
    $('table.pretty-table > tbody > tr:even').addClass("even");
    if (workstation) {
      $('select').each(function () {
       if ($(this).val() == '') {
        make_select_widget('Choose',$(this));
       } else if ($(this).find("option:selected").html()) {
        make_select_widget($(this).find("option:selected").html(),$(this));
       } else {
        make_select_widget($(this).find("option:first").html(),$(this));
       }
     }); 
   }

  } /* end if (!ready_ran) */
  ready_ran = true;



  $.keyboard.layouts['de'] = {
    'default' : [
      "\u0302 1 2 3 4 5 6 7 8 9 0 \u00df \u0301 {b}",
      "{tab} q w e r t z u i o p \u00fc +",
      "a s d f g h j k l \u00f6 \u00e4 # {e}",
      "{shift} < y x c v b n m , . - {shift}",
      "{c} {clear} {alt} {space} {alt} {a}"
    ],
    'shift' : [
      '\u00b0 ! " \u00a7 $ % & / ( ) = ? \u0300 {b}',
      "{tab} Q W E R T Z U I O P \u00dc *",
      "A S D F G H J K L \u00d6 \u00c4 ' {e}",
      "{shift} > Y X C V B N M ; : _ {shift}",
      "{c} {clear} {alt} {space} {alt} {a}"
    ],
    'alt' : [
      '\u0302 1 \u00b2 \u00b3 4 5 6 { [ ] } \\ \u0301 {b}',
      "{tab} @ w \u20ac r t z u i o p \u00fc \u0303",
      "a s d f g h j k l \u00f6 \u00e4 # {e}",
      "{shift} \u007c y x c v b n \u00b5 , . - {shift}",
      "{c} {clear} {alt} {space} {alt} {a}"
    ]
  };
  $.keyboard.layouts['en-US'] = {
    'default' : [
      "` 1 2 3 4 5 6 7 8 9 0 - = {b}",
      "{tab} q w e r t y u i o p [ ]",
      "a s d f g h j k l ; ' \\ {e}",
      "{shift} z x c v b n m , . / {shift}",
      "{c} {clear} {alt} {space} {alt} {a}"
    ],
    'shift' : [
      "~ ! @ # $ % ^ & * ( ) _ + {b}",
      "{tab} Q W E R T Y U I O P { }",
      'A S D F G H J K L : " | {e}',
      "{shift} Z X C V B N M < > ? {shift}",
      "{c} {clear} {alt} {space} {alt} {a}"
    ],
    'alt' : [
      '~ ! " \u00a3 \u20ac \u00b2 \u00b3 & * ( ) _ + {b}',
      "{tab} q w e r t y u i o p { }",
      'a s d f g h j k l : " | {e}',
      "{shift} z x c v b n m < > ? {shift}",
      "{c} {clear} {alt} {space} {alt} {a}"
    ]
  };
  $.keyboard.layouts['en-GB'] = {
    'default' : [
      "` 1 2 3 4 5 6 7 8 9 0 - = {b}",
      "{tab} q w e r t y u i o p [ ]",
      "a s d f g h j k l ; ' # {e}",
      "{shift} \\ z x c v b n m , . / {shift}",
      "{c} {clear} {alt} {space} {alt} {a}"
    ],
    'shift' : [
      '\u00ac ! " \u00a3 $ % ^ & * ( ) _ + {b}',
      "{tab} Q W E R T Y U I O P { }",
      "A S D F G H J K L : @ ~ {e}",
      "{shift} | Z X C V B N M < > ? {shift}",
      "{c} {clear} {alt} {space} {alt} {a}"
    ],
    'alt' : [
      '\u00a6 ! " \u00a3 \u20ac \u00b2 \u00b3 7 8 9 0 - = {b}',
      "{tab} q w e r t y u i o p [ ]",
      "a s d f g h j k l ; ' # {e}",
      "{shift} \\ z x c v b n m , . / {shift}",
      "{c} {clear} {alt} {space} {alt} {a}"
    ]
  };
  $.keyboard.layouts['en-AU'] = $.keyboard.layouts['en-US'];
  $.keyboard.layouts['fr'] = {
    'default' : [
      "\u00b2 & \u00e9 \" ' ( - \u00e8 _ \u00e7 \u00e0 ) = {b}",
      "{tab} a z e r t y u i o p \u02c4 $",
      "q s d f g h j k l m \u00f9 * {e}",
      "{shift} < w x c v b n , ; : ! {shift}",
      "{c} {clear} {alt} {space} {alt} {a}"
    ],
    'shift' : [
      "\u00b2 1 2 3 4 5 6 7 8 9 0 \u00b0 + {b}",
      "{tab} A Z E R T Y U I O P \u00a8 \u00a3",
      "Q S D F G H J K L M % \u00b5 {e}",
      "{shift} > W X C V B N ? . / \u00a7 {shift}",
      "{c} {clear} {alt} {space} {alt} {a}"
    ],
    'alt' : [
      "\u00b2 & \u00e9 # { [ \u00a6 ` \\ ^ @ ] } {b}",
      "{tab} a z \u20ac r t y u i o p \u00a4 $",
      "q s d f g h j k l m \u00f9 * {e}",
      "{shift} < w x c v b n , ; : ! {shift}",
      "{c} {clear} {alt} {space} {alt} {a}"
    ]
  };
  $.keyboard.layouts['num'] = {
    'default' : [
      "7 8 9",
      "4 5 6",
      "1 2 3",
      "{clear} 0 ,",
      "{c} {a}"
    ]
  };

  $.keyboard.layouts['num_old'] = {
    'default' : [
      '{cancel} {clear} {bksp}',
      '1 2 3 4',
      '5 6 7 8',
      '9 0 - .',
      '{accept}'
    ]
  };

  setInterval('checkFocusInput()',200);

});
// END DOCUMENT READY FUNCTIONS











//ORDER RELATED FUNCTIONS -- THESE SHOULD GO INTO ORDERSJS.JS OR ORDERS.JS.COFFEE
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
  get('/orders/update_pos_display?ajax=true', filename);
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



//POS RELATED FUNCTIONS

function updateDrawer(obj) {
  $('.pos-cash-register-amount').html(toCurrency(obj.amount));
  $('.eod-drawer-total').html(toCurrency(obj.amount));
  $('#header_drawer_amount').html(toCurrency(obj.amount));
}




// MATH RELATED FUNCTIONS
function Round(Number, DecimalPlaces) {
 return Math.round(parseFloat(Number) * Math.pow(10, DecimalPlaces)) / Math.pow(10, DecimalPlaces);
}

function RoundFixed(Number, DecimalPlaces) {
 return Round(Number, DecimalPlaces).toFixed(DecimalPlaces);
}

function toFloat(str, returnString) {
  if (str == '') {return 0.0;}
  if (returnString == null) returnString = false;
  if (typeof str == 'number') {
    return str;
  }
  if (str.match(/\d+\.\d+\,\d+/)) {
    str = str.replace('.','');
  }
  var ac = [0,1,2,3,4,5,6,7,8,9,'.',',','-'];
  var nstr = '';
  for (var i = 0; i < str.length; i++) {
    c = str.charAt(i);
    if (inArray(c,ac)) {
      if (c == ',') {
        nstr = nstr + '.';
      } else {
        nstr = nstr + c;
      }
    }
  }
  return (returnString) ? nstr : parseFloat(nstr);
}

function roundNumber(num, dec) {
  var result = Math.round(num*Math.pow(10,dec))/Math.pow(10,dec);
  return result;
}

function toDelimited(number) {
  var match, property, integerPart, fractionalPart;
  var settings = {
    precision: 2,
    unit: i18nunit,
    separator: i18nseparator,
    delimiter : i18ndelimiter
  };

  match = number.toString().match(/([\+\-]?[0-9]*)(.[0-9]+)?/);

  if (!match) return;

  integerPart = match[1].replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1" + settings.delimiter);
  fractionalPart = match[2] ? (match[2].toString() + "000000000000").substr(1, settings.precision) : "000000000000".substr(1, settings.precision);

  return integerPart + ( settings.precision > 0 ? settings.separator + fractionalPart : "");
}

function toCurrency(number) {
  var match, property, integerPart, fractionalPart;
  var settings = {         precision: 2,
    unit: i18nunit,
    separator: i18nseparator,
    delimiter : i18ndelimiter
  };

  match = number.toString().match(/([\+\-]?[0-9]*)(.[0-9]+)?/);

  if (!match) return;

  integerPart = match[1].replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1" + settings.delimiter);
  fractionalPart = match[2] ? (match[2].toString() + "000000000000").substr(1, settings.precision) : "000000000000".substr(1, settings.precision);

  return settings.unit + integerPart + ( settings.precision > 0 ? settings.separator + fractionalPart : "");
}

function toPercent(number) {
  var match, property, integerPart, fractionalPart;
  var settings = {         precision: 0,
    unit: "%",
    separator: i18nseparator,
    delimiter : i18ndelimiter
  };

  match = number.toString().match(/([\+\-]?[0-9]*)(.[0-9]+)?/);

  if (!match) return;

  integerPart = match[1].replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1" + settings.delimiter);
  fractionalPart = match[2] ? (match[2].toString() + "000000000000").substr(1, settings.precision) : "000000000000".substr(1, settings.precision);

  return '' + integerPart + ( settings.precision > 0 ? settings.separator + fractionalPart : "") + settings.unit;
}





// PRINT RELATED FUNCTIONS

function print_order(id) {
   print_url(Register.thermal_printer,'/orders/print_receipt', '&order_id=' + id);
}

function print_url(printer_path,url,params) {
  param_string = '?user_id=' + User.id + '&user_type=' + User.type + '&cash_register_id=' + Register.id + params;
  if (typeof SalorPrinter != 'undefined' && Register.salor_printer == true) {
    Salor.stopDrawerObserver(Register.cash_drawer_path);
    SalorPrinter.printURL(printer_path, Conf.url + url + param_string);
  } else {
    $.get(url + param_string);
  }
}

// DEBUG RELATED FUNCTIONS

function dbg(obj) {
  var str = '';
  alert(obj.width);
  for (var prop in obj) {
    str = str + " " + prop + ":" +obj[prop];
  }
  alert(str);
}

/**
 * Safe version of console.log
 **/
function clog() {
  try {
    if (typeof Salor != 'undefined') {
        // i.e. Salor object is only defined when we are inside of salor gui...
    } else {
      console.log(arguments);
    }
  } catch(e){
  }
}


// ERROR RELATED FUNCTIONS




// SALOR BIN RELATED FUNCTIONS

function playSound(file) {
  if (typeof Salor != 'undefined') {
    Salor.playSound(file);
  }
}


// STYLE RELATED FUNCTIONS

function salorGetOffset( el ) {
  var _x = 0;
  var _y = 0;
  while( el && !isNaN( el.offsetLeft ) && !isNaN( el.offsetTop ) ) {
      _x += el.offsetLeft - el.scrollLeft;
      _y += el.offsetTop - el.scrollTop;
      el = el.offsetParent;
  }
  return { top: _y, left: _x };
}

function get_position(x,y) {
	var z = x;
	x = 1/Math.sqrt(2) * (z - y);
	y = 1/Math.sqrt(2) * (z + y);
	return {x: x, y: y};
}

var _currentSelectTarget = '';
var _currentSelectButton;
function make_select_widget(name,elem) {
  elem.hide();
  var button = div();
  button.html($(elem).find("option:selected").text());
  if (button.html() == "")
    button.html($(elem).find("option:first").text());
  if (button.html() == "")
    button.html("Choose");
  button.insertAfter(elem);
  button.attr('select_target',"#" + elem.attr("id"));
  button.addClass("select-widget-button select-widget-button-" + elem.attr("id"));
  button.mousedown(function () {
    var pos = $(this).position();
    var off = $(this).offset();
    var mdiv = div();
    _currentSelectTarget = $(this).attr("select_target");
    _currentSelectButton = $(this);
    mdiv.addClass("select-widget-display select-widget-display-" + _currentSelectTarget.replace("#",""));
    var x = 0;
    $(_currentSelectTarget).children("option").each(function () {
      var d = div();
      d.html($(this).text());
      d.addClass("select-widget-entry select-widget-entry-" + _currentSelectTarget.replace("#",""));
      d.attr("value", $(this).attr('value'))
      d.mousedown(function () {
       $(_currentSelectTarget).find("option:selected").removeAttr("selected"); 
       $(_currentSelectTarget).find("option[value='"+$(this).attr('value')+"']").attr("selected","selected");
       $(_currentSelectTarget).find("option[value='"+$(this).attr('value')+"']").change(); 
       _currentSelectButton.html($(this).html());
       $('.select-widget-display').hide();
      });
      mdiv.append(d);
      x++;
      if (x == 4) {
        x = 0;
        mdiv.append("<br />");
      }

    });
    mdiv.css({position: 'absolute', left: MX - 50, top: MY - 50});
    $('body').append(mdiv);
    mdiv.show();
  });
}



function scrollable_div(elem) {
  if (elem.hasClass('scrollable-done')) {
    return;
  }
  var row = $('<div class="scrollable-button-row" align="right"></div>');
  var up = $('<div class="button-up">&and;</div>');
  var down = $('<div class="button-down" >&or;</div>');
  var spw = $('<div class="scrollable-space-wide">&nbsp;&nbsp;</div>');
  var sp = $('<div class="spacer-rmargin">&nbsp;</div>');
  up.mousedown(function () {
    var e = elem;
    var t = e.scrollTop() - 100;
    if (t < 0) {
      t = 0
    }
    e.scrollTop(t);
  });
  down.mousedown(function () {
    var e = elem;
    var y = elem.offset().top;
    var t = top + 30;
    elem.css({position: 'relative', top: t + 'px'});
  });
  row.append(down);
  row.append(spw);
  row.append(sp);
  row.append(up);

  var x = elem.offset().left;
  var y = elem.offset().top;
  var h = elem.height();
  var w = elem.width();
  $('body').append(row);
  var css = {position: 'absolute',top: (y + h +100) + 'px', left: (x + w - 100) + 'px'};
  row.css(css);
}

function div() {
  return $('<div></div>');
}

function td(elem,opts) {
  var e = div();
  if (opts && opts.classes) {
    e.addClass(opts.classes.join(' '));
  }
  e.addClass('jtable-cell');
  e.append(elem);
  return e;
}

function tr(elements,opts) {
  var e = div();
  if (opts && opts.classes) {
    e.addClass(opts.classes.join(' '));
  }
  e.addClass('table-row');
  for (var i = 0; i < elements.length; i++) {
    e.append(elements[i]);
  }
  return e;
}

function span_wrap(text,cls) {
  return '<span class="' + cls + '">'+text+'</span>';
}

function div_wrap(text,cls) {
  return '<div class="' + cls + '">'+text+'</div>';
}

function make_action_button(elem) {
  if (elem.hasClass("action-button-done")) {
    return elem;
  }
  elem.mousedown(function () {
    var elem = $(this);
    get($(this).attr('url'), filename );
    if ($(this).attr('update_pos_display') == 'true') {
      update_pos_display();
      update_order_items();
    }
    if ($(this).attr('refresh') == 'true') {
      location.reload();
    }
  });
  elem.addClass("action-button-done pointer");
  return elem;
}

/*
var MX,MY;
$(document).mousemove(function(e){
  MX = e.pageX;
  MY = e.pageY;
});
*/




// ONSCREEN KEYBOARD RELATED FUNCTIONS

function make_keyboardable(elem) {
  if (elem.hasClass('keyboardable-done')) {
    return;
  }
  var kbd = $('<div class="kbd-show-button">&crarr;</div>');

  kbd.mousedown(function () {
    elem.getkeyboard().reveal();
  });
  if (!elem.hasClass('keyboardable-int')) {
    if (elem.hasClass("keyboard-input")) {
        elem.keyboard({
          openOn   : '',
          stayOpen : true,
          layout       : i18nlocale,
          customLayout : null,
          accepted    : function () {
            add_item($("#keyboard_input").val(),'');
          },
          visible: function(){ $('.ui-keyboard-preview').select(); }
        });
    } else {
      elem.keyboard({
        openOn   : '',
        stayOpen : true,
        layout       : i18nlocale,
        customLayout : null,
        visible: function(){ $('.ui-keyboard-preview').select(); }
      });
    }
  } else {
    elem.keyboard({
      openOn      : '',
      stayOpen    : true,
      layout       : 'num',
      customLayout : null,
      visible: function(){ $('.ui-keyboard-preview').select(); }
    });
  }
  elem.addClass("keyboardable-done");
  if (elem.hasClass('left-kbd')) {
    kbd.addClass('kbd-show-left pointer');
    kbd.insertBefore(elem);
  } else {
    kbd.addClass('kbd-show pointer');
    kbd.insertAfter(elem);
    if (elem.hasClass("keyboard-input")) {
      kbd.insertAfter(elem);
      kbd.css({display: 'inline-block'});
    }
  }

  return elem;
}


function make_keyboardable_with_options(elem,opts) {
  if (elem.hasClass('keyboardable-done')) {
    return;
  }
  var kbd = $('<div class="kbd-show-button">&crarr;</div>');
  kbd.attr('target_id',"#" + elem.attr('id'));
  kbd.click(function () {
    var target = $(this).attr('target_id');
    $(target).getkeyboard().reveal();
  });
  kbd.addClass('kbd-show pointer');
  var options = {
        openOn   : '',
        stayOpen : true,
        layout       : i18nlocale,
        customLayout : null,
      };
  for (opt in opts) {
    options[opt] = opts[opt];
  }
  options["visible"]=function(){ $('.ui-keyboard-preview').select(); };
  if (elem.hasClass('keyboardable-int')) {
    options['layout'] = 'num';    
  }
  elem.keyboard(options);
 kbd.insertAfter(elem);
  return elem;
}

function isEditItem() {
  if (params.controller == 'items') {
    if (['new','create','edit','update'].indexOf(params.action) != -1) {
      return true;
    }
  }
}

function isEditItemLocation() {
  if (params.controller == 'items') {
    if (params.action == 'update_location') {
      return true;
    }
  }
}
function isEditItemRealQuantity() {
  if (params.controller == 'items') {
    if (params.action == 'update_real_quantity') {
      return true;
    }
  }
}
function isShipmentsEdit() {
  if (params.controller == 'shipments') {
    if (params.action == 'new' || params.action == 'edit') {
      return true;
    }
  }
}

function isDiscountsEdit() {
  if (params.controller == 'discounts') {
    if (params.action == 'new' || params.action == 'edit') {
      return true;
    }
  }
}

function isCustomersEdit() {
  if (params.controller == 'customers') {
    if (params.action == 'new' || params.action == 'edit') {
      return true;
    }
  }
}

function handleKeyboardInput(event) {
  var handled = false;
  key = event.which;
  if ((key == 13) && handleKeyboardEnter){ //i.e. enter key
    var cf = $('.salor-focused');
    if (cf.hasClass('inplaceeditinput') && cf.val() != '') {
      $('#inplaceeditsave').trigger('click');
      handled = true;
    } else if (cf.hasClass('shipment-items-input') && cf.hasClass('attr-input-sku')) {
      cf.trigger('blur');
      handled = true;
    } else if (cf.attr('id') == 'search_keywords') {
      search();
      event.preventDefault();
      return false;
    }
    if ($('#keyboard_input').val()) {
      //keypad_callbacks['Enter'].call(this);
      add_item($('#keyboard_input').val(),'');
      handled = true;
    } else {
      //we aren't on the pos screen, so we should have some generic behaviors
      if (params.controller == "shippers") {
        handled = true;
      }
      focusInput($('#keyboard_input'));
    }
    if ($('#generic_search_input').length != 0 && $('#generic_search_input').val() != '') {
      generic_search();
      handled = true;
      return false;
    }
    if (isEditItem()) {
      handled = true;
      return false;
    }
    if (isEditItemLocation()) {
      update_location_submit();
      handled = true;
      return false;
    }
    if (isEditItemRealQuantity()) {
      update_real_quantity_submit();
      handled = true;
      return false;
    }
    if (isShipmentsEdit()) {
      shipments_edit_handler(event.target);
      handled = true;
      return false;
    }
    if (isDiscountsEdit() || isCustomersEdit()) {
      handled = true;
      return false;
    }
  }
  if (handled == true) {
    event.preventDefault();
    return false;
  } else {
    return true;
  }
}



// VARIOUS HELPER FUNCTIONS

function set_selected(elem,value,type) { /* 0: Match text, 1: match option value*/
  if (value == null) {
    return elem;
  }
  elem.children("option").each(function () {
    if (type == 0) {
      if ($(this).html() == value) {
        $(this).attr('selected',true);
      }
    } else {
      if ($(this).attr('value') == value) {
        $(this).attr('selected',true);
      }
    }
  });
  return elem;
}

function confirm_link(link,message) {
  var answer = confirm(message)
  if (answer){
    window.location = link;
  }
}

function cancel_confirm(cancel_func,confirm_func) {
  var row = $('<div class="button-row" align="right"></div>');
  var can = $('<div class="button-cancel">' + i18n_menu_cancel + '</div>');
  can.mousedown(cancel_func);
  var comp = $('<div class="button-confirm">' + i18n_menu_done + '</div>');
  comp.mousedown(confirm_func);
  var sp = $('<div class="spacer-rmargin">&nbsp;</div>');
  var spw = $('<div class="spacer-rmargin">&nbsp;&nbsp;&nbsp;</div>');
  row.append(can);
  var x = Math.random(4);
  if (x == 0) { x = 1;}
  var t = 0;
  for (var i = 0; i <= x; i++) {
    if (t == 0) {
      row.append(sp);
      t = 1;
    } else {
      row.append(spw);
      t = 0;
    }
  }
  row.append(comp);
  return row;
}

function get(url, calledFrom, sFunc, type, eFunc) {
  if (type == null) type = 'get';
  type = type.toLowerCase();
  if (type !== 'get' && type != 'post') type = 'get';
  if (sFunc == null) sFunc = function(){};
  if (eFunc == null) eFunc = function(){};

  $.ajax({
    url: url,
    context: document.body,
    success: sFunc,
    error: function(jqXHR, textStatus, errorThrown) {
      eFunc();
     // alert(textStatus + "--" + errorThrown + "\nCalled from: " + calledFrom + "\nURL: " + url);
    }
  });
}

function make_in_place_edit(elem) {
  if (elem.hasClass('editmedone')) {
    return;    
  }
  elem.click(function (event) {
    in_place_edit($(this).attr('id'),event.pageX,event.pageY);
  });
  elem.addClass('editmedone');
}


function make_toggle(elem) {
  elem.css({ cursor: 'pointer'});
  elem.mousedown(function () {
    var elem = $(this);
    get('/vendors/toggle?' +
      'field=' + elem.attr('field') +
      '&klass=' + elem.attr('klass') +
      '&value=' + elem.attr('value') +
      '&model_id=' + elem.attr('model_id'),
    filename
  );
    if (elem.attr('rev')) {
      elem.attr('src',elem.attr('rev'));
    }
    if (elem.attr('refresh') == 'true') {
      location.reload(true);
    }
  });
  return elem;
}

function arrayCompare(a1, a2) {
  if (a1.length != a2.length) return false;
  var length = a2.length;
  for (var i = 0; i < length; i++) {
    if (a1[i] !== a2[i]) return false;
  }
  return true;
}

function inArray(needle, haystack) {
  var length = haystack.length;
  for(var i = 0; i < length; i++) {
    if(typeof haystack[i] == 'object') {
      if(arrayCompare(haystack[i], needle)) return true;
    } else {
      if(haystack[i] == needle) return true;
    }
  }
  return false;
}


function make_dt_button(btn) {
  if (btn.hasClass("btn-done")) {
    return;
  }
  btn.mousedown(function (event) {
    $('.dt-tag-button').removeClass("highlight");
    $(this).addClass("highlight");
    if ($(this).attr('value') == 'None'){
      $('#dt_tag').val($(this).attr('value'));
      $('.dt-tag-target').html(i18n_transaction_tag_one);
    } else {
      $('#dt_tag').val($(this).attr('value'));
      $('.dt-tag-target').html($(this).html());
    }
    $('.dt-tags').hide();
   });
  btn.addClass("button-done");
}




// KEYPRESS RELATED FUNCTIONS

/*
  This is the new key press function, find someway to hook the current
  key functionality because something weird is happening with NUMPAD keys,
  so we took it over in the c code.
*/
function salorKeyRelease(keyCode) {
  alert(keyCode);
}

var handled = false;
var handleKeyboardEnter = true;
var keypressHandler = function(){}; // This is for the new global keypress handling. Pass in a reference to handler here
var oldKeypressHandler = function(){};
var onEnterKey = function(event){}; // Some function to specifically handle the Enter key being pressed
var oldOnEnterKey = function(event){};
var onEscKey = function(){}; // Some function to specifically handle the Escape key being pressed
var oldOnEscKey = function(){};
var ENTER_KEY = 13;
var ESC_KEY = 27;
var onF2Key = function (event) {
  if ($(".last-five-orders").is(":visible")) {
    $(".last-five-orders").hide();
    var skey = 49;
    for (var i = 0; i < 5; i++) {
      keypressMap[skey] = null;
      skey = skey + 1;
    }
  } else {
    $(".last-five-orders").show();
    var skey = 49;
    for (var i = 0; i < 5; i++) {
      keypressMap[skey] = function (event) {
        var skey = (event.which) ? event.which : event.keyCode;
        var loc = $('.last-five-orders-' + skey).attr('location');
        window.location = loc;
      }
      skey = skey + 1;
    }
  }
} // end onF2Key

var onEndKey = function(event) {
  if (params.controller == 'orders' && params.action == 'new') {
    get('/orders/show_payment_ajax?order_id=' + $('.order-id').html());
  }
}

var keypressMap = {
  13: onEnterKey,
  27: onEscKey
};

var oldKeypressMap = {
  13: onEnterKey,
  27: onEscKey
};

function getKeypressCodeArr(codes) {
  var codeStr = String(codes);
  var codeArr = [];
  var tmpArr = codeStr.split(',');
  for (i=0; i<tmpArr.length; i++) {
    // check each of these to see if they split out into a range
    var rangeArr = tmpArr[i].split('-');
    if (rangeArr.length > 1) {
      for (j=parseInt(rangeArr[0]); j<=parseInt(rangeArr[1]); j++) {
        codeArr.push(j);
      }
    } else {
      codeArr.push(rangeArr[0]);
    }
  }
  return codeArr;
}

function setKeypressHandler(code, func) {
  var codeArr = getKeypressCodeArr(code);
  for (i=0; i<codeArr.length; i++) {
    oldKeypressMap[code] = (keypressMap[code]) ? keypressMap[codeArr[i]] : function(){};
    keypressMap[codeArr[i]] = func;
  }
}

function unsetKeypressHandler(code) {
  var codeArr = getKeypressCodeArr(code);
  for (i=0; i<codeArr.length; i++) {
    keypressHandler = (oldKeypressMap[codeArr[i]]) ? oldKeypressMap[code] : function(){};
    oldKeypressMap[codeArr[i]] = function(){};
  }
}

function setOnEnterKey(func) {
  setKeypressHandler(ENTER_KEY, func);
}

function unsetOnEnterKey() {
  unsetKeypressHandler(ENTER_KEY);
}

function setOnEscKey(func) {
  setKeypressHandler(ESC_KEY, func);
}

function unsetOnEscKey() {
  unsetKeypressHandler(ESC_KEY);
}

function bindFirstLetter(word, func, bothCases) {
  if (bothCases == null) bothCases = false;
  var bindChar = word.charAt(0);
  var isUpperCase = (bindChar.toUpperCase() == bindChar) ? true : false;
  setKeypressHandler(bindChar.charCodeAt(0), func);
  if (bothCases) {
    if (isUpperCase) {
      bindChar = bindChar.toLowerCase();
    } else {
      bindChar = bindChar.toUpperCase();
    }
    setKeypressHandler(bindChar.charCodeAt(0), func);
  }
}

function unbindFirstLetter(word, bothCases) {
  if (bothCases == null) bothCases = false;
  var bindChar = word.charAt(0);
  var isUpperCase = (bindChar.toUpperCase() == bindChar) ? true : false;
  unsetKeypressHandler(bindChar.charCodeAt(0));
  if (bothCases) {
    if (isUpperCase) {
      bindChar = bindChar.toLowerCase();
    } else {
      bindChar = bindChar.toUpperCase();
    }
    unsetKeypressHandler(bindChar.charCodeAt(0));
  }
}

function bindInplaceEnter(doBind) {
  if (doBind == null) doBind = true;
  try {
    inplaceEditBindEnter(doBind);
  } catch(e){}
}


// FOCUS RELATED FUNCTIONS

function checkFocusInput() {
  if (focuseKeyboardInput) {
    focusInput($('#keyboard_input'));
    focuseKeyboardInput = false;
  }
}

function focusInput(inp) {
  $('.salor-focused').removeClass('salor-focused');
  inp.addClass('salor-focused');
  inp.focus();
}





// IN PLACE EDIT RELATED FUNCTIONS

/**
 * This allows us to easily turn off the binding to the enter key when we need
 * something else to catch it
 */
function inplaceEditBindEnter(doBind, id) {
  $('#inplaceedit').unbind('keypress');
  if (doBind) {
	$('#inplaceedit').bind('keypress', function (e) {
			var code = (e.keyCode ? e.keyCode : e.which);
			 if(code == 13) { //Enter keycode
				   in_place_edit_go(id);
			 }
 	});
 }
}

function in_place_edit_go(id) {
  var type = $('#' + id).attr('field');
	var datatype = $('#' + id).attr('data_type');
	var klass = $('#' + id).attr('klass');
	var withstring = $('#' + id).attr('withstring');
	withstring = withstring + '&ajax=true';
	var value = $('#' + id).html();


  var final_value = $('#inplaceedit').val();
  final_value = final_value.replace("%",'');
  var string = '/vendors/edit_field_on_child?id='+ $('#' + id).attr('model_id') +'&klass='+klass+'&field='+type+'&value=' + final_value + '&' + withstring
  get(string, '_in_place_edit.html.erb', function () {
  });
  if ($('#' + id).attr('update_pos_display') == 'true') {
    update_order_items();
    update_pos_display();
  }
  if ($('#inplaceedit')[0].tagName == 'SELECT') {
    $('#' + id).html($('#inplaceedit option:selected').html());
  } else {
    $('#' + id).html(final_value);
  }

  $('#inplaceedit-div').remove();
  if ($('#keyboard_input').length != 0) {
    focuseKeyboardInput = true;
  }
}

function in_place_edit(id,x,y) {
  $('#inplaceedit-div').remove();
  var type = $('#' + id).attr('field');
  var datatype = $('#' + id).attr('data_type');
  var klass = $('#' + id).attr('klass');
  var withstring = $('#' + id).attr('withstring');
  withstring = withstring + '&ajax=true';
  var value = $('#' + id).html();

  if (value == '' || value == null) {
    value = i18n_value_not_set;
  }

  if (field_types[type]) {
    field = field_types[type].call(this,value);
  } else {
    var field = $("<input type='text' class='inplaceeditinput' id='inplaceedit' value='"+value+"' />");
  }
  if (fields_callbacks[type]) {
    fields_callbacks[type].call(this,field);
  }

  var savelink = '<a id="inplaceeditsave" class="button-confirm">' + i18n_menu_ok + '</a>';
  var cancellink = '<a id="inplaceeditcancel" class="button-cancel">' + i18n_menu_cancel + '</a>';
  var linktable = "<table class='inp-menu' align='right'><tr><td>"+cancellink+"</td><td>"+savelink+"</td></tr></table>";

  if (id == 'pos_order_total') {
    x = x - 200;
  }
  if ($('#' + id).hasClass('pos-item-total') || $('#' + id).hasClass('pos-item-rebate')) {
    x = x - 200;
  }
  var offset = {'top' : 20, 'left' : '20%', 'position' : 'absolute', 'width': '60%'}
  var div = $("<div id='inplaceedit-div'></div>");
  $('body').append(div);
  div.append(field);
  div.append('<br />');
  div.append(linktable);

  if (field[0].tagName != 'SELECT') {
          field.keyboard({
            openOn   : 'focus',
            stayOpen : true,
            layout       : field.hasClass('keyboardable-int') ? 'num' : i18nlocale,
            customLayout : null,
            visible : function(){ $('.ui-keyboard-preview').select();},
            accepted: function(){ in_place_edit_go(id); }
          });
          field.getkeyboard().reveal();
          $('#inplaceedit-div').hide();
  }

  $('#inplaceedit-div').css(offset);
  $('#inplaceeditsave').mousedown(function () {
		  in_place_edit_go(id);
		  focuseKeyboardInput = true;
  });
  $('#inplaceeditcancel').mousedown(function () {
		  $('#inplaceedit-div').remove();
		  focuseKeyboardInput = true;
  });

  if (type == 'datepicker') {
	  $('#inplaceedit').datepicker();
  }
  inplaceEditBindEnter(true, id);
  //div.children('.kbd-show-button').trigger('mousedown');
  //focusInput($('#inplaceedit'));
}

var fields_callbacks = {
  rebate: function (elem) {
    elem.addClass("keyboardable-int");
    elem.addClass("rebate-amount");
  },
  price: function (elem) {
    elem.addClass("keyboardable-int");
  },
  quantity: function (elem) {
    elem.addClass("keyboardable-int");
  },
  tax: function (elem) {
    elem.addClass("keyboardable-int");
  },
  subtotal: function (elem) {
    elem.addClass("keyboardable-int");
  },
  total: function (elem) {
    elem.addClass("keyboardable-int");
  },
  points: function (elem) {
    elem.addClass("keyboardable-int");
  },
  lc_points: function (elem) {
    elem.addClass("keyboardable-int");
  },
  tax_profile_amount: function (elem) {
    elem.addClass("keyboardable-int");
  }
};


var receiver_shipper_select = function (value) {
  s = $(inplace_ships);
  s = set_selected(s,value,0);
  return s;
}

var field_types = {
  category_id: function (value) {
    s = $(inplace_cats);
    s = set_selected(s,value,0);
    return s;
  },
  vendor_id: function (value) {
    s = $(inplace_stores);
    s = set_selected(s,value,0);
    return s;
  },
  location_id: function (value) {
    s = $(inplace_locations);
    s = set_selected(s,value,0);
    return s;
  },
  item_type_id: function (value) {
    s = $(inplace_itemtypes);
    s = set_selected(s,value,0);
    return s;
  },
  status: function (value) {
    s = $(inplace_shipmentstatuses);
    s = set_selected(s,value,0);
    return s;
  },
  rebate_type: function (value) {
    s = $("inplace_rebatetypes");
    s = set_selected(s,value,1);
    return s;
  },
  the_shipper: receiver_shipper_select,
  the_receiver: receiver_shipper_select
};


// CAMERA RELATED FUNCTIONS

//if (typeof Salor != 'undefined') {
//  function snapCam() {
//    Salor.captureCam(0,'<%= ::Rails.root.to_s  %>/public/images/cameras/camera-0.png',1);
//    setTimeout("snapCam()",2000);
//  }
//  //setTimeout("snapCam()",2000);
//}
