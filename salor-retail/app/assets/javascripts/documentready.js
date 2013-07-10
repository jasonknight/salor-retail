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

  // TODO: This should go into stylesheets
  $('#order_items_table tr:even').addClass('even');
  $('.stripe-me tr:even').addClass('even');
  $('tr.no-stripe').removeClass('even');
  $('.stripe-me2:even').addClass('even');
  $('div.stripe-me > div.table-row:even').addClass('even');
  $('#generic_search_input').val('');
  $('.list-view tr:even').addClass('even')
  $('.list-view tr:last').removeClass('even')
  $('tr.no-stripe').removeClass('even');
  $('table.pretty-table > tbody > tr:even').addClass("even");

  // FOR FANCY CHECKBOXES:
  $('input:checkbox:not([safari])').checkbox();
  $('input[safari]:checkbox').checkbox({cls:'jquery-safari-checkbox'});
  $('input:radio').checkbox();
  

  $('.toggle').each(function () {
      make_toggle($(this));
  });
  
  $('.dt-tag-button').each(function () { make_dt_button($(this));});
  

  // inplace edit
  $('.editme').each(function () {
    make_in_place_edit($(this));                  
  });
  
  
  // make select widget
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

  // focus stuff
  focusInput($('#generic_search_input'));
  setInterval('checkFocusInput()',200);
  
  // don't run this twice, a known jQuery bug
  ready_ran = true;
});
