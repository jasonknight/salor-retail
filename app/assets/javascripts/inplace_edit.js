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
    s = $(inplace_rebatetypes);
    s = set_selected(s,value,1);
    return s;
  },
  the_shipper: receiver_shipper_select,
  the_receiver: receiver_shipper_select
};

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
  },
  rebate_type: function (elem) {
    //make_select_widget('xxx',elem);
  }
};

function make_in_place_edit(elem) {
  if (elem.hasClass('editmedone')) {
    return;    
  }
  elem.click(function (event) {
    in_place_edit($(this).attr('id'),event.pageX,event.pageY);
  });
  elem.addClass('editmedone');
}

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
  if (field[0].tagName == 'SELECT') {
    make_select_widget('', $('#inplaceedit'));
  }
  inplaceEditBindEnter(true, id);
  //div.children('.kbd-show-button').trigger('mousedown');
  //focusInput($('#inplaceedit'));
}




var receiver_shipper_select = function (value) {
  s = $(inplace_ships);
  s = set_selected(s,value,0);
  return s;
}
