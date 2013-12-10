var receiver_shipper_select = function (value) {
  s = $(inplace_ships);
  s = set_selected(s,value,0);
  return s;
}

sr.fn.inplace_edit.get_inputs = {
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

sr.fn.inplace_edit.field_callbacks = {
  rebate: function (elem) {
    elem.addClass("keyboardable-int");
    elem.addClass("rebate-amount");
  },
  price: function (elem) {
    elem.addClass("keyboardable-int");
  },
  purchase_price: function (elem) {
    elem.addClass("keyboardable-int");
  },
  purchase_price_total: function (elem) {
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



/**
 * This allows us to easily turn off the binding to the enter key when we need
 * something else to catch it
 */
sr.fn.inplace_edit.bindEnter = function(elem) {
  $('#inplaceedit').unbind('keypress');
  $('#inplaceedit').bind('keypress', function (e) {
    var code = (e.keyCode ? e.keyCode : e.which);
    if(code == 13) {
      sr.fn.inplace_edit.submit(elem);
    }
  });
}

sr.fn.inplace_edit.make = function(elem) {
  if (elem.hasClass('editmedone')) {
    return;    
  }
  elem.click(function (event) {
    var x = event.pageX;
    var y = event.pageY;
    
    var field = elem.attr('field');
    var type = elem.attr('type');
    var keyboard_layout = elem.attr('keyboard_layout');
    var withstring = elem.attr('withstring');
    var value = elem.html();

    if (sr.fn.inplace_edit.get_inputs[field]) {
      console.log('getting inputs');
      var inputhtml = sr.fn.inplace_edit.get_inputs[field](value);
    } else {
      console.log('setting text input field');
      var inputhtml = "<input type='text' class='inplaceeditinput' id='inplaceedit' value='"+value+"' />";
    }
    var input = $(inputhtml);

    if (sr.fn.inplace_edit.field_callbacks[field]) {
      console.log("callback for", field);
      sr.fn.inplace_edit.field_callbacks[field](input);
    }

    if (typeof type == 'undefined') {
      console.log('type is undefined');
      // the type attr has not been set on the element, so we get type depeding on the input element used
      var tagname = input[0].tagName
      console.log('tagname is', tagname);

      switch(tagname) {
        case 'SELECT':
          type = 'select';
          break;
        case 'INPUT':
          type = 'keyboard';
          break;
      }
    }
      
    switch(type) {
      case 'keyboard':
        if ( input.hasClass('keyboardable-int') || keyboard_layout == 'num' ) {
          keyboard_layout = 'num';
        } else {
          keyboard_layout = i18nlocale;
        }
        input.keyboard({
          openOn   : 'focus',
          stayOpen : true,
          layout   : keyboard_layout,
          customLayout : null,
          position: {
            of: $('.yieldbox'),
            my: 'center center',
            at: 'center center'
          },
          visible : function() { 
            if (IS_APPLE_DEVICE) {
              $('.ui-keyboard-preview').val("");
            } 
            $('.ui-keyboard-preview').select();
          },
          accepted: function() {
            sr.fn.inplace_edit.submit(elem, input.val());
          }
        });
        input.getkeyboard().reveal();
        $('#inplaceedit-div').hide();
        break;
      
      case 'select':
        make_select_widget('', $('#inplaceedit'));
        break;
        
      case 'date':
        elem.hide();
        input.insertAfter(elem);
        input.datepicker({
          onSelect: function(date, inst) {
            elem.show();
            sr.fn.inplace_edit.submit(elem, input.val());
            input.remove();
          }
        });
        input.datepicker('show');
        break;
    }

    //$('#inplaceedit-div').css(offset);
    $('#inplaceeditsave').mousedown(function() {
      sr.fn.inplace_edit.submit(elem);
    });

    $('#inplaceeditcancel').mousedown(function() {
      $('#inplaceedit-div').remove();
    });

    sr.fn.inplace_edit.bindEnter(elem);
    
  });
  elem.addClass('editmedone');
}




sr.fn.inplace_edit.submit = function(elem, value) {
  console.log(value);
  var field = elem.attr('field');
  var klass = elem.attr('klass');
  var withstring = elem.attr('withstring');
  var model_id = elem.attr('model_id');
  
  value = value.replace("%",'');
  
  elem.html(value);
  
  var string = '/vendors/edit_field_on_child?id=' + model_id +'&klass=' + klass + '&field=' + field + '&value=' + value + '&' + withstring;
  get(string, 'inplace_edit.js');

  $('#inplaceedit-div').remove();
}



