/*
  _fetch is a quick way to fetch a result from the server.
 */
// function _fetch(url,callback) {
//   $.ajax({
//     url: url,
//     context: window,
//     success: callback
//   });
// }

/*
 *  _push is a quick way to deliver an object to the server
 *  It takes a data object, a string url, and a success callback.
 *  Additionally, you can pass, after those three an error callback,
 *  and an object of options to override the options used with
 *  the ajax request.
 */
// function _push(object) {
//   var payload = null;
//   var callback = null;
//   var error_callback = function (jqXHR,status,err) {
//   };
//   var user_options = {};
//   var url;
//   for (var i = 0; i < arguments.length; i++) {
//     switch(typeof arguments[i]) {
//       case 'object':
//         if (!payload) {
//           payload = {currentview: 'push', model: {}}
//           $.each(arguments[i], function (key,value) {
//             payload[key] = value;
//           });
//         } else {
//           user_options = arguments[i];
//         }
//         break;
//       case 'function':
//         if (!callback) {
//           callback = arguments[i];
//         } else {
//           error_callback = arguments[i];
//         }
//         break;
//       case 'string':
//         url = arguments[i];
//         break;
//     }
//   }
//   options = { 
//     context: window,
//     url: url, 
//     type: 'post', 
//     data: payload, 
//     timeout: 20000, 
//     success: callback, 
//     error: error_callback
//   };
//   if (typeof user_options == 'object') {
//     $.each(user_options, function (key,value) {
//       options[key] = value;
//     });
//   }
//   $.ajax(options);
// }

// function make_toggle(elem) {
//   elem.css({ cursor: 'pointer'});
//   elem.mousedown(function () {
//     var elem = $(this);
//     get('/vendors/toggle?' +
//       'field=' + elem.attr('field') +
//       '&klass=' + elem.attr('klass') +
//       '&value=' + elem.attr('value') +
//       '&model_id=' + elem.attr('model_id'),
//     filename
//   );
//     if (elem.attr('rev')) {
//       elem.attr('src',elem.attr('rev'));
//     }
//     if (elem.attr('refresh') == 'true') {
//       location.reload(true);
//     }
//   });
//   return elem;
// }


/*
  Call this function on an input that you want to have auto complete functionality.
  requires a jquery element, a dictionary (array, or object, or hash mapping)
  options, which is an object where the only required key is the field if you use an object, or hash mapping, then a callback,
  which is what function to run when someone clicks a search result.
  
  On an input try:
  
  auto_completable($('#my_input'),['abc yay','123 ghey'],{},function (result) {
      alert('You chose ' + result);
  });
  in the callback, $(this) == $('#my_input')
 */
function auto_completable(element,dictionary,options,callback) {
  var key = 'auto_completable.' + element.attr('id');
  element.attr('auto_completable_key',key);
  _set(key + ".dictionary",dictionary,element); // i.e. we set the context of the variable to the element so that it will be gc'ed
  _set(key + ".options", options,element);
  _set(key + ".callback", callback,element);
  element.on('keyup',function () {
    var val = $(this).val();
    var key = $(this).attr('auto_completable_key');
    var results = [];
    if (val.length > 2) {
      var options = _get(key + '.options',$(this));
      var dictionary = _get(key + ".dictionary",$(this));
      if (options.map) { 
        // We are using a hash map, where terms are organized by first letter, then first two letters
        var c = val.substr(0,1).toLowerCase();
        var c2 = val.substr(0,2).toLowerCase();
        // i.e. if the search term is doe, the check to see if dictionary['d'] is set
        if (dictionary[c]) {
          // i.e. if the search term is doe, the check to see if dictionary['do'] is set
          if (dictionary[c][c2]) {
            // i.e. we consider dictionary['do'] to be an array of objects
            for (var i in dictionary[c][c2]) {
              // we assume that you have set options { field: "name"} or some such
              if (dictionary[c][c2][i][options.field].toLowerCase().indexOf(val.toLowerCase()) != -1) {
                results.push(dictionary[c][c2][i]);
              }
            }
          }
        }
      } else { // We assume that it's just an array of possible values
        for (var i = 0; i < dictionary.length; i++) {
          if (options.field) {
            if (dictionary[i][options.field].indexOf(val.toLowerCase()) != -1) {
              results.push(dictionary[i])
            } 
          } else {
            if (dictionary[i].indexOf(val.toLowerCase()) != -1) {
              results.push(dictionary[i])
            } 
          }
        }
      }
    }
    auto_completable_show_results($(this),results);
  });
}
function auto_completable_show_results(elem,results) {
  $('#auto_completable').remove();
  if (results.length > 0) {
    var key = elem.attr('auto_completable_key');
    var options = _get(key + '.options',elem);
    ac = create_dom_element('div',{id: 'auto_completable'},'',$('body'));
    var offset = elem.offset();
    var css = {left: offset.left, top: offset.top + elem.outerHeight(), width: elem.outerWidth() + ($.support.boxModel ? 0 : 2)};
    ac.css(css);
    for (var i in results) {
      var result = results[i];
      var div = create_dom_element('div',{'class': 'result'},result[options.field],ac);
      // i.e. we set up the vars we will need on the callback on the element in context
      _set('auto_completable.result',result,div);
      _set('auto_completable.target',elem,div);
      div.on('mousedown', function () {
        var target = _get('auto_completable.target',$(this));
        var result = _get('auto_completable.result',$(this));
        var key = target.attr('auto_completable_key');
        var callback = _get(key + ".callback",target);
        callback.call(target,result,$(this)); //i.e. the callback will be executed with the input as this, the result is the first argument
        // the last optional argument will be the origin of the event, i.e. the div
        $('#auto_completable').remove();
      });
    }
  }
}

/* Pass in a hex code to get back an object of red, green, blue*/
function to_rgb(hex) {
  var h = (hex.charAt(0)=="#") ? hex.substring(1,7):h;
  var r = parseInt(h.substring(0,2),16);
  var g = parseInt(h.substring(2,4),16);
  var b = parseInt(h.substring(4,6),16);
  return {red: r, green: g, blue: b};
}
