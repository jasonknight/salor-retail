// VARIOUS HELPER FUNCTIONS

function set_selected(elem,value,type) { /* 0: Match text, 1: match option value*/
  if (value == null) {
    return elem;
  }
  elem.children("option").each(function () {
    if (type == 0) {
      if ($(this).html() == value) {
        $(this).attr('selected',true);
      }
    } else {
      if ($(this).attr('value') == value) {
        $(this).attr('selected',true);
      }
    }
  });
  return elem;
}

function confirm_link(link,message) {
  var answer = confirm(message)
  if (answer){
    window.location = link;
  }
}

function cancel_confirm(cancel_func,confirm_func) {
  var row = $('<div id="cancel_confirm_buttons" class="button-row" align="right"></div>');
  var can = $('<div id="cancel" class="button-cancel">' + i18n.menu.cancel + '</div>');
  can.mousedown(cancel_func);
  var comp = $('<div id="confirm" class="button-confirm">' + i18n.menu.ok + '</div>');
  comp.mousedown(confirm_func);
  var sp = $('<div class="spacer-rmargin">&nbsp;</div>');
  var spw = $('<div class="spacer-rmargin">&nbsp;&nbsp;&nbsp;</div>');
  row.append(can);
  var x = Math.random(4);
  if (x == 0) { x = 1;}
  var t = 0;
  for (var i = 0; i <= x; i++) {
    if (t == 0) {
      row.append(sp);
      t = 1;
    } else {
      row.append(spw);
      t = 0;
    }
  }
  row.append(comp);
  return row;
}

function get(url, calledFrom, sFunc, type, eFunc) {
  if (type == null) type = 'get';
  type = type.toLowerCase();
  if (type !== 'get' && type != 'post') type = 'get';
  if (sFunc == null) sFunc = function(){};
  if (eFunc == null) eFunc = function(){};
  
  echo('get');
  
  var datestamp = new Date().getTime();
  sendqueue.push(datestamp);
  disablePrintReceiptButton();

  $.ajax({
    url: url,
    success: sFunc,
    complete: function () {
      var idx = sendqueue.indexOf(datestamp);
      sendqueue.splice(idx, 1);
      enablePrintReceiptButton();
    },
    error: function(jqXHR, textStatus, errorThrown) {
      eFunc();
     // alert(textStatus + "--" + errorThrown + "\nCalled from: " + calledFrom + "\nURL: " + url);
    }
  });
}

function make_toggle(elem) {
  elem.css({ cursor: 'pointer'});
  elem.mousedown(function () {
    var elem = $(this);
    get('/vendors/toggle?' +
      'field=' + elem.attr('field') +
      '&klass=' + elem.attr('klass') +
      '&value=' + elem.attr('value') +
      '&model_id=' + elem.attr('model_id'),
    filename
  );
    if (elem.attr('rev')) {
      elem.attr('src',elem.attr('rev'));
    }
    if (elem.attr('refresh') == 'true') {
      location.reload(true);
    }
  });
  return elem;
}

function arrayCompare(a1, a2) {
  if (a1.length != a2.length) return false;
  var length = a2.length;
  for (var i = 0; i < length; i++) {
    if (a1[i] !== a2[i]) return false;
  }
  return true;
}

function inArray(needle, haystack) {
  var length = haystack.length;
  for(var i = 0; i < length; i++) {
    if(typeof haystack[i] == 'object') {
      if(arrayCompare(haystack[i], needle)) return true;
    } else {
      if(haystack[i] == needle) return true;
    }
  }
  return false;
}

   
