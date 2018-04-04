sr.fn.onscreen_keyboard.setup = function() {
  $('.keyboardable').each(function(i, el) {
    sr.fn.onscreen_keyboard.make($(el));
  });
  
  $('.keyboardable-int').each(function(i, el) {
    sr.fn.onscreen_keyboard.make($(el));
  });


  // i18n layout definitions
  $.keyboard.layouts['gn'] = {
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

    $.keyboard.layouts['en'] = {
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
      "{b} +",
      "7 8 9",
      "4 5 6",
      "1 2 3",
      "{clear} 0 ,",
      "{c} {a}",
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

}
  

sr.fn.onscreen_keyboard.make = function(elem) {
  if (elem.hasClass('keyboardable-done')) {
    return;
  }
  var kbd = $('<div id="' + elem.attr("id") + '_kbd" class="kbd-show-button">&crarr;</div>');

  kbd.mousedown(function () {
    elem.getkeyboard().reveal();
  });
  
  var new_offset = elem.offset();
  new_offset.top += 2;
  kbd.css({position: 'relative', margin: elem.css('margin')});
  
  if (elem.attr('id') == 'main_sku_field') {
    elem.keyboard({
      openOn   : '',
      stayOpen : true,
      layout       : i18nlocale,
      customLayout : null,
      accepted    : function () {
        sr.fn.pos_core.addItem($("#main_sku_field").val(),'');
      },
      visible: function(){ $('.ui-keyboard-preview').select(); }
    });
  } else if (elem.attr('id') == 'main_shipment_sku_field') {
    elem.keyboard({
      openOn   : '',
      stayOpen : true,
      layout       : i18nlocale,
      customLayout : null,
      accepted: function() {
        shipments.submitLineItem($('#main_shipment_sku_field').val());
      },
      visible: function(){ $('.ui-keyboard-preview').select(); }
    });
  } else if (elem.hasClass('keyboardable-int')) {
    elem.keyboard({
      openOn   : '',
      stayOpen : true,
      layout       : 'num',
      customLayout : null,
      visible: function(){ $('.ui-keyboard-preview').select(); }
    });
  } else {
    elem.keyboard({
      openOn      : '',
      stayOpen    : true,
      layout       : i18nlocale,
      customLayout : null,
      visible: function(){ $('.ui-keyboard-preview').select(); }
    });
  }
  
  elem.addClass("keyboardable-done");
  
  if (elem.hasClass('left-kbd')) {
    kbd.addClass('kbd-show-left pointer');
    kbd.insertAfter(elem);
    new_offset.left = new_offset.left - (kbd.outerWidth() + 10);
    //kbd.offset(new_offset);
  } else if (elem.hasClass('wide-left-kbd')) {
    kbd.addClass('kbd-show-left pointer');
    kbd.insertAfter(elem);
    new_offset.left = new_offset.left - (kbd.outerWidth() + 36);
    //kbd.offset(new_offset);
  } else {
    kbd.addClass('kbd-show pointer');
    kbd.insertAfter(elem);
    if (elem.hasClass("keyboard-input")) {
      kbd.insertAfter(elem);
      
    }
    new_offset.left += elem.outerWidth();
    //kbd.offset(new_offset);
  }

  return elem;
}


sr.fn.onscreen_keyboard.makeWithOptions = function(elem,opts) {
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
  kbd.css({position: 'relative', margin: elem.css('margin')});
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
      if (sr.data.session.other.is_apple_device) {
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
  //kbd.offset(new_offset);
  return elem;
}