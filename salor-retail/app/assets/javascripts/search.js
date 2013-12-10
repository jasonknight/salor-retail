// the following is for the generic search on the top right corner of the screen

function searchSetup() {
  $('#generic_search_input').keyup(function(e) {
    if (e.keyCode == 13) {
      generic_search('#generic_search_input');
    }
  })
}

function generic_search(caller) {
  window.location = '?keywords=' + $('#generic_search_input').val();
}

// the following is for the search popup on the POS screen
var current_page = 1;

function showSearch() {
  $('#search').show();
  $('#search').css({'z-index':'1010'});
  $('#search_keywords').val("");
  sr.fn.focus.set($('#search_keywords'));
  var inp = $('<input type="text" id="search_keywords" name="keywords" class="keyboardable" value="" />');
  inp.keyup(function(e) {
    if (e.keyCode == 13) {
      search('#search_keywords');
      inp.select();
    }
  })
  $('.search-div-input-constrainer').html(inp);
  sr.fn.onscreen_keyboard.make(inp);
  $('#search').height($(window).height() * 0.75);
  $('#search').width($(window).width() * 0.75);
  $('.search-results').height($('#search').height() - 136);
  inp.select();
  shared.helpers.center($('#search'));
}

function hideSearch() {
  $('#search').hide();
  $('#search_results').html('');
  setTimeout(function () {
    sr.fn.focus.set($('#keyboard_input'));
  },120);
}

function search(caller) {
  sr.fn.debug.echo('search', caller);
  var query = '/items/search?keywords=' + $('#search_keywords').val() + '&klass=' + $('#search_models').val() + '&page=' + current_page;
  get(query, '_search.html.erb');
}

function search_get_next_page() {
  current_page = current_page + 1;
  search('search_get_next_page');
}

function search_get_prev_page() {
  current_page = current_page - 1;
  search('search_get_prev_page');
}