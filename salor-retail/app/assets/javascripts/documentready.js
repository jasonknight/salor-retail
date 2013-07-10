var focuseKeyboardInput = false;
var calledFrom = 'TopOfAppJS';
var filename = "_application_js.html.erb";

$(function () {
  if ( !useMimo() && isSalorBin()) {
    Salor.poleDancer(Register.pole_display, '     S A L O R      Next Generation POS' );
  }
  
  if (isSalorBin()) {
    Salor.stopDrawerObserver();
  }

  jQuery.expr[':'].focus = function( elem ) {
    return elem === document.activeElement && ( elem.type || elem.href );
  };

  $('#order_items_table tr:even').addClass('even');
  $('.stripe-me tr:even').addClass('even');
  $('tr.no-stripe').removeClass('even');
  $('.stripe-me2:even').addClass('even');
  $('div.stripe-me > div.table-row:even').addClass('even');
  $('#generic_search_input').val('');
  $('.list-view tr:even').addClass('even')
  $('.list-view tr:last').removeClass('even')
  $('tr.no-stripe').removeClass('even');

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

  setInterval('checkFocusInput()',200);
});
