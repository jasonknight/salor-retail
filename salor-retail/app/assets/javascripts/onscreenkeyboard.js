function make_keyboardable(elem) {
  if (elem.hasClass('keyboardable-done')) {
    return;
  }
  var kbd = $('<div id="' + elem.attr("id") + '_kbd"class="kbd-show-button">&crarr;</div>');

  kbd.mousedown(function () {
    elem.getkeyboard().reveal();
  });
  var new_offset = elem.offset();
  new_offset.top += 2;
  kbd.css({position: 'absolute', height: elem.outerHeight() - (elem.outerHeight() * 0.25), margin: elem.css('margin')});
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
    $('body').append(kbd);
    new_offset.left = new_offset.left - (kbd.outerWidth() + 10);
    kbd.offset(new_offset);
  } else if (elem.hasClass('wide-left-kbd')) {
    kbd.addClass('kbd-show-left pointer');
    $('body').append(kbd);
    new_offset.left = new_offset.left - (kbd.outerWidth() + 36);
    kbd.offset(new_offset);
  } else {
    kbd.addClass('kbd-show pointer');
    kbd.insertAfter(elem);
    if (elem.hasClass("keyboard-input")) {
      kbd.insertAfter(elem);
      
    }
    new_offset.left += elem.outerWidth();
    kbd.offset(new_offset);
  }

  return elem;
}


function make_keyboardable_with_options(elem,opts) {
  if (elem.hasClass('keyboardable-done')) {
    return;
  }
  var kbd = $('<div id="' + elem.attr("id") + '_kbd"class="kbd-show-button">&crarr;</div>');
  kbd.attr('target_id',"#" + elem.attr('id'));
  kbd.click(function () {
    var target = $(this).attr('target_id');
    $(target).getkeyboard().reveal();
  });
  kbd.addClass('kbd-show pointer');
  var new_offset = elem.offset();
  new_offset.top += 2;
  kbd.css({position: 'absolute', height: elem.outerHeight() - (elem.outerHeight() * 0.25), margin: elem.css('margin')});
  var options = {
        openOn   : '',
        stayOpen : true,
        layout       : i18nlocale,
        customLayout : null,
      };
  for (opt in opts) {
    options[opt] = opts[opt];
  }
  // we have to check cause sometimes we pass in a visible func that is special
  // as is the case with payment methods
  if (!options["visible"]) {
    options["visible"]= function(){ 
      if (IS_APPLE_DEVICE) {
        $(".ui-keyboard-preview").val("");
      }
      $('.ui-keyboard-preview').select(); 
    };
  }
  if (elem.hasClass('keyboardable-int')) {
    options['layout'] = 'num';    
  }
  elem.keyboard(options);
  kbd.insertAfter(elem);
  new_offset.left += elem.outerWidth() + 10;
  kbd.offset(new_offset);
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
