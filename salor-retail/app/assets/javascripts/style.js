var _currentSelectTarget = '';
var _currentSelectButton;

function make_select_widget(name,elem) {
  if (elem.children("option").length > 10) {
    return;
  }
  elem.hide();
  // Find the max length
  var max_len = 0;
  
  elem.children("option").each(function () {
    var txt = $(this).text();
    if (txt.length > max_len) {
      max_len = txt.length;
    }
  });
  var char_width = 8;
  var button = $('<div id="select_widget_button_for_' + elem.attr("id") + '"></div>');
  button.html($(elem).find("option:selected").text());
  if (button.html() == "")
    button.html($(elem).find("option:first").text());
  if (button.html() == "")
    button.html(name);
  button.insertAfter(elem);
  button.attr('select_target',"#" + elem.attr("id"));
  button.addClass("select-widget-button select-widget-button-" + elem.attr("id"));
  
  
  button.click(function () {
    var pos = $(this).position();
    var off = $(this).offset();
    var mdiv = div();
    _currentSelectTarget = $(this).attr("select_target");
    _currentSelectButton = $(this);
    mdiv.addClass("select-widget-display select-widget-display-" + _currentSelectTarget.replace("#",""));
    mdiv.css({width: (max_len * char_width + 50) * 2});
    var x = 0;
    $(_currentSelectTarget).children("option").each(function () {
      var d = $('<div id="active_select_'+$(this).attr('value').replace(':','-')+'"></div>');
      d.html($(this).text());
      d.addClass("select-widget-entry select-widget-entry-" + _currentSelectTarget.replace("#",""));
      d.attr("value", $(this).attr('value'));
      d.css({width: max_len * char_width, overflow: 'hidden'});
      d.click(function () {
       $(_currentSelectTarget).find("option:selected").removeAttr("selected"); 
       $(_currentSelectTarget).find("option[value='"+$(this).attr('value')+"']").attr("selected","selected");
       $(_currentSelectTarget).find("option[value='"+$(this).attr('value')+"']").change(); 
       _currentSelectButton.html($(this).html());
       var input_id = _currentSelectTarget.replace("type","amount");
       setTimeout(function () { $(input_id).select(); },55);
       $('.select-widget-display').hide();
       _
      });
      mdiv.append(d);
      x++;
      if (x == 4) {
        x = 0;
        mdiv.append("<br />");
      }

    });
    mdiv.css({position: 'absolute'});
    $('body').append(mdiv);
    mdiv.offset({left: button.offset().left - 1, top: button.offset().top - 1});
    mdiv.show();
  });
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

function div_wrap(text,cls) {
  return '<div class="' + cls + '">'+text+'</div>';
}


var MX,MY;
$(document).mousemove(function(e){
  MX = e.pageX;
  MY = e.pageY;
});


function make_dt_button(btn) {
  if (btn.hasClass("btn-done")) {
    return;
  }
  btn.mousedown(function (event) {
    $('.dt-tag-button').removeClass("highlight");
    $(this).addClass("highlight");
    if ($(this).attr('value') == 'None'){
      $('#dt_tag').val($(this).attr('value'));
      $('.dt-tag-target').html(i18n.activerecord.models.transaction_tag.one);
    } else {
      $('#dt_tag').val($(this).attr('value'));
      $('.dt-tag-target').html($(this).html());
    }
    $('.dt-tags').hide();
   });
  btn.addClass("button-done");
}
