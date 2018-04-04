function get(url, calledFrom, sFunc, type, eFunc) {
  if (type == null) type = 'get';
  type = type.toLowerCase();
  if (type !== 'get' && type != 'post') type = 'get';
  if (sFunc == null) sFunc = function(){};
  if (eFunc == null) eFunc = function(){};
  
  var datestamp = new Date().getTime();
  sr.data.complete.sendqueue.push(datestamp);
  sr.fn.complete.disablePrintReceiptButton();

  $.ajax({
    url: url,
    success: sFunc,
    complete: function () {
      var idx = sr.data.complete.sendqueue.indexOf(datestamp);
      sr.data.complete.sendqueue.splice(idx, 1);
      sr.fn.complete.enablePrintReceiptButton();
    },
    error: function(jqXHR, textStatus, errorThrown) {
      eFunc();
      sr.data.messages.prompts.push("Error during request to" + url + "<br><br>Please contact customer service.");
      sr.fn.messages.displayMessages();
    }
  });
}

function onCashDrawerClose() {
  sr.fn.complete.hidePopup();
}

function checkLength( o, n, min, max ) {
  if ( o.val().length > max || o.val().length < min ) {
    o.addClass( "ui-state-error" );
    updateTips( "Length of " + n + " must be between " +
    min + " and " + max + "." );
    return false;
  } else {
    return true;
  }
}

function updateTips( t ) {
  $(".validateTips")
  .text( t )
  .addClass( "ui-state-highlight" );
}

function _get(name,context) {
  if (context) {
    // if you pass in a 3rd argument, which should be an html element, then that is set as teh context.
    // this ensures garbage collection of the values when that element is removed.
    return $.data(context[0],name);
  } else {
    return $.data(document.body,name);
  }
}

function _set(name,value,context) {
  if (context) {
    // if you pass in a 3rd argument, which should be an html element, then that is set as teh context.
    // this ensures garbage collection of the values when that element is removed.
    return $.data(context[0],name,value);
  } else {
    return $.data(document.body,name,value);
  } 
}