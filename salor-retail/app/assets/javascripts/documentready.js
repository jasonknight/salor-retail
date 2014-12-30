var sr = {
  fn: {
    pos_core: {},
    buttons: {},
    coin_calculator: {},
    change: {},
    payment: {},
    complete: {},
    customers: {},
    debug: {},
    drawer: {},
    user_logins: {},
    focus: {},
    inplace_edit: {},
    inventory: {},
    invoice: {},
    items: {},
    math: {},
    messages: {},
    onscreen_keyboard: {},
    refund: {},
    remotesupport: {},
    salor_bin: {},
    search_generic: {},
    search_pos: {},
    shipments: {},
    shippers: {},
    session: {},
    
    
  },
  data: {
    resources: {},
    session: {
      params: {},
      user: {},
      vendor: {},
      drawer: {},
      cash_register: {},
      other: {},
    },
    pos_core: {},
    complete: {},
    inplace_edit: {},
    messages: {
      notices: [],
      alerts: [],
      prompts: [],
    },
    search_pos: {},
    shipments: {},
    various: {},
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
  
  if (sr.fn.salor_bin.is()) {
    Salor.stopDrawerObserver();
  }

  jQuery.expr[':'].focus = function( elem ) {
    return elem === document.activeElement && ( elem.type || elem.href );
  };

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
  
  if (typeof sr.data.session.params != 'undefined' &&
    (
      (sr.data.session.params.controller == 'orders' && sr.data.session.params.action == 'new') ||
      (sr.data.session.params.controller == 'items' && sr.data.session.params.action == 'index')
    )
  ) {
    $('.yieldbox').css('width', '100%');
    $('.yieldbox').css('padding-left', '0px');
    $('.yieldbox').css('padding-right', '0px');
  }
  

//   $('.toggle').each(function () {
//     make_toggle($(this));
//   });
  
  $('.dt-tag-button').each(function () {
    sr.fn.drawer.makeTagButtons($(this));
  });
  

  // inplace edit
  $('.editme').each(function () {
    sr.fn.inplace_edit.make($(this));                  
  });
  
  
  // make select widget
  if (sr.data.session.other.workstation == true) {
    $('select').each(function () {
      if ($(this).val() == '') {
        shared.makeSelectWidget(i18n.views.single_words.choose,$(this));
      } else if ($(this).find("option:selected").html()) {
        shared.makeSelectWidget($(this).find("option:selected").html(),$(this));
      } else {
        shared.makeSelectWidget($(this).find("option:first").html(),$(this));
      }
    }); 
  } 

  // focus stuff
  //focusInput($('#generic_search_input'));
  
  jQuery.ajaxSetup({
      'beforeSend': function(xhr) {
          //xhr.setRequestHeader("Accept", "text/javascript");
          xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
      }
  });
  
  $("#category_color").modcoder_excolor();
  
  $('#btn-' + sr.data.session.params.controller + '-' + sr.data.session.params.action).addClass('active');
  
  //TODO: move the following functions to the individual views. they needn't be loaded for every page.
  sr.fn.coin_calculator.setup();
  sr.fn.focus.setup();
  sr.fn.inventory.setup();
  sr.fn.invoice.setup();
  sr.fn.onscreen_keyboard.setup();
  sr.fn.search_generic.setup();
  sr.fn.messages.displayMessages();
  
  $(document).mousemove(function(e){
    sr.data.various.mouse_x = e.pageX;
    sr.data.various.mouse_y = e.pageY;
  });
  
  sr.data.session.other.is_apple_device = navigator.userAgent.match(/iPhone|iPad|iPod/i) != null;
  
  // don't run this twice, a known jQuery bug
  ready_ran = true;
});
