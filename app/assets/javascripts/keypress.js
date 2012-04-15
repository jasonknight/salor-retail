/*
  This is the new key press function, find someway to hook the current
  key functionality because something weird is happening with NUMPAD keys,
  so we took it over in the c code.
*/
function salorKeyRelease(keyCode) {
  alert(keyCode);
}

var handled = false;
var handleKeyboardEnter = true;
var keypressHandler = function(){}; // This is for the new global keypress handling. Pass in a reference to handler here
var oldKeypressHandler = function(){};
var onEnterKey = function(event){}; // Some function to specifically handle the Enter key being pressed
var oldOnEnterKey = function(event){};
var onEscKey = function(){}; // Some function to specifically handle the Escape key being pressed
var oldOnEscKey = function(){};
var ENTER_KEY = 13;
var ESC_KEY = 27;
var onF2Key = function (event) {
  if ($(".last-five-orders").is(":visible")) {
    $(".last-five-orders").hide();
    var skey = 49;
    for (var i = 0; i < 5; i++) {
      keypressMap[skey] = null;
      skey = skey + 1;
    }
  } else {
    $(".last-five-orders").show();
    var skey = 49;
    for (var i = 0; i < 5; i++) {
      keypressMap[skey] = function (event) {
        var skey = (event.which) ? event.which : event.keyCode;
        var loc = $('.last-five-orders-' + skey).attr('location');
        window.location = loc;
      }
      skey = skey + 1;
    }
  }
} // end onF2Key

var onEndKey = function(event) {
  if (params.controller == 'orders' && params.action == 'new') {
    get('/orders/show_payment_ajax?order_id=' + $('.order-id').html());
  }
}

var keypressMap = {
  13: onEnterKey,
  27: onEscKey
};

var oldKeypressMap = {
  13: onEnterKey,
  27: onEscKey
};

function getKeypressCodeArr(codes) {
  var codeStr = String(codes);
  var codeArr = [];
  var tmpArr = codeStr.split(',');
  for (i=0; i<tmpArr.length; i++) {
    // check each of these to see if they split out into a range
    var rangeArr = tmpArr[i].split('-');
    if (rangeArr.length > 1) {
      for (j=parseInt(rangeArr[0]); j<=parseInt(rangeArr[1]); j++) {
        codeArr.push(j);
      }
    } else {
      codeArr.push(rangeArr[0]);
    }
  }
  return codeArr;
}

function setKeypressHandler(code, func) {
  var codeArr = getKeypressCodeArr(code);
  for (i=0; i<codeArr.length; i++) {
    oldKeypressMap[code] = (keypressMap[code]) ? keypressMap[codeArr[i]] : function(){};
    keypressMap[codeArr[i]] = func;
  }
}

function unsetKeypressHandler(code) {
  var codeArr = getKeypressCodeArr(code);
  for (i=0; i<codeArr.length; i++) {
    keypressHandler = (oldKeypressMap[codeArr[i]]) ? oldKeypressMap[code] : function(){};
    oldKeypressMap[codeArr[i]] = function(){};
  }
}

function setOnEnterKey(func) {
  setKeypressHandler(ENTER_KEY, func);
}

function unsetOnEnterKey() {
  unsetKeypressHandler(ENTER_KEY);
}

function setOnEscKey(func) {
  setKeypressHandler(ESC_KEY, func);
}

function unsetOnEscKey() {
  unsetKeypressHandler(ESC_KEY);
}

function bindFirstLetter(word, func, bothCases) {
  if (bothCases == null) bothCases = false;
  var bindChar = word.charAt(0);
  var isUpperCase = (bindChar.toUpperCase() == bindChar) ? true : false;
  setKeypressHandler(bindChar.charCodeAt(0), func);
  if (bothCases) {
    if (isUpperCase) {
      bindChar = bindChar.toLowerCase();
    } else {
      bindChar = bindChar.toUpperCase();
    }
    setKeypressHandler(bindChar.charCodeAt(0), func);
  }
}

function unbindFirstLetter(word, bothCases) {
  if (bothCases == null) bothCases = false;
  var bindChar = word.charAt(0);
  var isUpperCase = (bindChar.toUpperCase() == bindChar) ? true : false;
  unsetKeypressHandler(bindChar.charCodeAt(0));
  if (bothCases) {
    if (isUpperCase) {
      bindChar = bindChar.toLowerCase();
    } else {
      bindChar = bindChar.toUpperCase();
    }
    unsetKeypressHandler(bindChar.charCodeAt(0));
  }
}

function bindInplaceEnter(doBind) {
  if (doBind == null) doBind = true;
  try {
    inplaceEditBindEnter(doBind);
  } catch(e){}
}
