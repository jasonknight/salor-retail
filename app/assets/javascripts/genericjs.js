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

  if (typeof(Salor) != 'undefined' && $Register.pole_display != '') {
    Salor.poleDancer($Register.pole_display, '     S A L O R      Next Generation POS' );
  }
});

function initErrors() {
  $('.errors').show();
  var back = $('<div style="float: left;"><%= image_tag "/images/icons/" + icon(:back,32) %></div>');
  var del = $('<div align="right"><%= image_tag "/images/icons/" + icon(:delete,32) %></div>');
  del.click(function () {
    $(this).parent().hide();
  });
  back.click(function () {
    history.go(-1);
  });
  $('.errors').append(back);
  $('.errors').append(del);
}
