function salorGetOffset( el ) {
  var _x = 0;
  var _y = 0;
  while( el && !isNaN( el.offsetLeft ) && !isNaN( el.offsetTop ) ) {
      _x += el.offsetLeft - el.scrollLeft;
      _y += el.offsetTop - el.scrollTop;
      el = el.offsetParent;
  }
  return { top: _y, left: _x };
}

function get_position(x,y) {
	var z = x;
	x = 1/Math.sqrt(2) * (z - y);
	y = 1/Math.sqrt(2) * (z + y);
	return {x: x, y: y};
}

var _currentSelectTarget = '';
var _currentSelectButton;
function make_select_widget(name,elem) {
  elem.hide();
  var button = div();
  button.html($(elem).find("option:selected").text());
  if (button.html() == "")
    button.html($(elem).find("option:first").text());
  if (button.html() == "")
    button.html("Choose");
  button.insertAfter(elem);
  button.attr('select_target',"#" + elem.attr("id"));
  button.addClass("select-widget-button select-widget-button-" + elem.attr("id"));
  button.mousedown(function () {
    var pos = $(this).position();
    var off = $(this).offset();
    var mdiv = div();
    _currentSelectTarget = $(this).attr("select_target");
    _currentSelectButton = $(this);
    mdiv.addClass("select-widget-display select-widget-display-" + _currentSelectTarget.replace("#",""));
    var x = 0;
    $(_currentSelectTarget).children("option").each(function () {
      var d = div();
      d.html($(this).text());
      d.addClass("select-widget-entry select-widget-entry-" + _currentSelectTarget.replace("#",""));
      d.attr("value", $(this).attr('value'))
      d.mousedown(function () {
       $(_currentSelectTarget).find("option:selected").removeAttr("selected"); 
       $(_currentSelectTarget).find("option[value='"+$(this).attr('value')+"']").attr("selected","selected");
       $(_currentSelectTarget).find("option[value='"+$(this).attr('value')+"']").change(); 
       _currentSelectButton.html($(this).html());
       $('.select-widget-display').hide();
      });
      mdiv.append(d);
      x++;
      if (x == 4) {
        x = 0;
        mdiv.append("<br />");
      }

    });
    mdiv.css({position: 'absolute', left: MX - 50, top: MY - 50});
    $('body').append(mdiv);
    mdiv.show();
  });
}



function scrollable_div(elem) {
  if (elem.hasClass('scrollable-done')) {
    return;
  }
  var row = $('<div class="scrollable-button-row" align="right"></div>');
  var up = $('<div class="button-up">&and;</div>');
  var down = $('<div class="button-down" >&or;</div>');
  var spw = $('<div class="scrollable-space-wide">&nbsp;&nbsp;</div>');
  var sp = $('<div class="spacer-rmargin">&nbsp;</div>');
  up.mousedown(function () {
    var e = elem;
    var t = e.scrollTop() - 100;
    if (t < 0) {
      t = 0
    }
    e.scrollTop(t);
  });
  down.mousedown(function () {
    var e = elem;
    var y = elem.offset().top;
    var t = top + 30;
    elem.css({position: 'relative', top: t + 'px'});
  });
  row.append(down);
  row.append(spw);
  row.append(sp);
  row.append(up);

  var x = elem.offset().left;
  var y = elem.offset().top;
  var h = elem.height();
  var w = elem.width();
  $('body').append(row);
  var css = {position: 'absolute',top: (y + h +100) + 'px', left: (x + w - 100) + 'px'};
  row.css(css);
}

function div() {
  return $('<div></div>');
}

function td(elem,opts) {
  var e = div();
  if (opts && opts.classes) {
    e.addClass(opts.classes.join(' '));
  }
  e.addClass('jtable-cell');
  e.append(elem);
  return e;
}

function tr(elements,opts) {
  var e = div();
  if (opts && opts.classes) {
    e.addClass(opts.classes.join(' '));
  }
  e.addClass('table-row');
  for (var i = 0; i < elements.length; i++) {
    e.append(elements[i]);
  }
  return e;
}

function span_wrap(text,cls) {
  return '<span class="' + cls + '">'+text+'</span>';
}

function div_wrap(text,cls) {
  return '<div class="' + cls + '">'+text+'</div>';
}

function make_action_button(elem) {
  if (elem.hasClass("action-button-done")) {
    return elem;
  }
  elem.mousedown(function () {
    var elem = $(this);
    get($(this).attr('url'), filename );
    if ($(this).attr('update_pos_display') == 'true') {
      update_pos_display();
      update_order_items();
    }
    if ($(this).attr('refresh') == 'true') {
      location.reload();
    }
  });
  elem.addClass("action-button-done pointer");
  return elem;
}

/*
var MX,MY;
$(document).mousemove(function(e){
  MX = e.pageX;
  MY = e.pageY;
});
*/

function make_dt_button(btn) {
  if (btn.hasClass("btn-done")) {
    return;
  }
  btn.mousedown(function (event) {
    $('.dt-tag-button').removeClass("highlight");
    $(this).addClass("highlight");
    if ($(this).attr('value') == 'None'){
      $('#dt_tag').val($(this).attr('value'));
      $('.dt-tag-target').html(i18n_transaction_tag_one);
    } else {
      $('#dt_tag').val($(this).attr('value'));
      $('.dt-tag-target').html($(this).html());
    }
    $('.dt-tags').hide();
   });
  btn.addClass("button-done");
}
