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

  if (typeof(Salor) != 'undefined' && Register.pole_display != '') {
    Salor.poleDancer(Register.pole_display, '     S A L O R      Next Generation POS' );
  }

  if (typeof(Salor) != 'undefined' && Register.pole_display == '') {
    Salor.mimoImage('/opt/salor/support/salor-retail-customerscreen-advertising.bmp');
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
//       if (isDiscountsEdit() || isCustomersEdit()) {
//         handled = true;
//         return false;
//       }
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
        make_select_widget(i18n.views.single_words.choose,$(this));
       } else if ($(this).find("option:selected").html()) {
        make_select_widget($(this).find("option:selected").html(),$(this));
       } else {
        make_select_widget($(this).find("option:first").html(),$(this));
       }
     }); 
   }

  } /* end if (!ready_ran) */
  ready_ran = true;



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
