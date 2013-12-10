var sr = {
  fn: {
    pos_core: {},
    buttons: {},
    coin_calculator: {},
  },
  data: {
    pos_core: {}
  },
}


var focuseKeyboardInput = false;
var calledFrom = 'TopOfAppJS';
var filename = "_application_js.html.erb";
var ready_ran = false;

$(function () {
  if (ready_ran == true) {
    return
  }
  
  if (isSalorBin()) {
    Salor.stopDrawerObserver();
  }

  jQuery.expr[':'].focus = function( elem ) {
    return elem === document.activeElement && ( elem.type || elem.href );
  };
  
  $('#generic_search_input').val('');

  $('.stripe-me tr:even').addClass('even');
  $('.stripe-me tr:odd').addClass('odd');
  $('tr.no-stripe').removeClass('even');
  $('.stripe-me2:even').addClass('even');
  $('.stripe-me2:odd').addClass('odd');
  //$('div.stripe-me > div.table-row:even').addClass('even');
  $('.list-view tr:even').addClass('even')
  $('.list-view tr:odd').addClass('odd')
  $('.list-view tr:last').removeClass('even')
  $('table.pretty-table > tbody > tr:even').addClass("even");

  // FOR FANCY CHECKBOXES:
  $('input:checkbox:not([safari])').checkbox();
  $('input[safari]:checkbox').checkbox({cls:'jquery-safari-checkbox'});
  $('input:radio').checkbox();
  
  if (typeof params != 'undefined' && ((params.controller == 'orders' && params.action == 'new') || (params.controller == 'items' && params.action == 'index'))) {
    $('.yieldbox').css('width', '100%');
    $('.yieldbox').css('padding-left', '0px');
    $('.yieldbox').css('padding-right', '0px');
  }
  

  $('.toggle').each(function () {
    make_toggle($(this));
  });
  
  $('.dt-tag-button').each(function () {
    make_dt_button($(this));
  });
  

  // inplace edit
  $('.editme').each(function () {
    make_in_place_edit($(this));                  
  });
  
  
  // make select widget
  if (typeof workstation != 'undefined') {
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

  // focus stuff
  //focusInput($('#generic_search_input'));
  
  $("#category_color").modcoder_excolor();
  
  sr.fn.coin_calculator.setup();
  
  // don't run this twice, a known jQuery bug
  ready_ran = true;
});
