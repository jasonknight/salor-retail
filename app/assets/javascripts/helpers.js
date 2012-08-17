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
  var can = $('<div id="cancel" class="button-cancel">' + i18n_menu_cancel + '</div>');
  can.mousedown(cancel_func);
  var comp = $('<div id="confirm" class="button-confirm">' + i18n_menu_ok + '</div>');
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

  $.ajax({
    url: url,
    context: document.body,
    success: sFunc,
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

window.shared = {
  element:function (tag,attrs,content,append_to) {
    if (attrs["id"] && $('#' + attrs["id"]).length != 0) {
      var elem = $('#' + attrs["id"]);
      _set('existed',true,elem);
      return elem;
    } else {
      element = $(document.createElement(tag));
      $.each(attrs, function (k,v) {
        element.attr(k, v);
      });
      element.html(content);
      if (append_to != '')
        $(append_to).append(element);
      return element;
    }
  },
  date: {
    hm: function (date,sep) {
      if (!date)
        date = new Date();
      if (!sep)
        sep = '';
      return [shared.helpers.pad(date.getHours(),'0',2),shared.helpers.pad(date.getMinutes(),'0',2)].join(sep);
    },
    ymd: function (date,sep) {
      if (!sep)
        sep = '';
      return [
      date.getFullYear(),
      shared.helpers.pad(date.getMonth() + 1,'0',2),
      shared.helpers.pad(date.getDate(),'0',2)
      ].join(sep); 
    },
    ymdhm: function (date,sep) {
      if (!sep)
        sep = '';
      return [
      date.getFullYear(),
      shared.helpers.pad(date.getMonth() + 1,'0',2),
      shared.helpers.pad(date.getDate(),'0',2),
      shared.helpers.pad(date.getHours(),'0',2),
      shared.helpers.pad(date.getMinutes(),'0',2)
      ].join(sep); 
    }
  },
  most_common: function (string,callback,cap,matches,start,start2,keys,results,sorted) {
    var time_start = new Date();
    if (!matches)
      matches = string.match(/(.{4,4})/g);
    if (!results)
      results = {};
    if (!start)
      start = 0;
    for (var i = start; i < matches.length; i++) {
      if (!results[matches[i]])
        results[matches[i]] = 1
        else
          results[matches[i]] += 1
          var now = new Date();
        if ((now - time_start) > 100) {
          setTimeout(function () {
            shared.most_common(string,callback,cap,matches,i+1,null,null,results,null);
          },50);
          return;
        }
    }
    if (!start2)
      start2 = 0;
    if (!keys)
      keys = Object.keys(results);
    if (!sorted)
      sorted = [];
    for (var j = start2; j < keys.length; j++) {
      sorted.push([keys[j],results[keys[j]]]);
      if ((now - time_start) > 100) {
        setTimeout(function () {
          shared.most_common(string,callback,cap,matches,matches.length,j+1,keys,results,sorted);
        },50);
        return;
      }
    }
    sorted.sort(function (a,b){
      if (a[1] > b[1]) {
        return 1;
      }
      if (a[1] < b[1]) {
        return -1;
      }
      return 0;
    });
    //     console.log(sorted);
    var new_sorted = [];
    if (!cap)
      cap = 10;
    if (sorted.length < cap)
      cap = sorted.length - 1;
    for (var ii = sorted.length-1; ii > sorted.length - cap; ii--) {
      new_sorted.push(sorted[ii][0]);
    }
    callback.call({},new_sorted);
  },
  compress: function (string,dictionary,callback,start,timer) {
    var time_start = new Date();
    if (!timer)
      timer = new Date();
    if (!start) {
      start = 0;
      console.log("Compressing: ",string.length," chars");
    }
    for (var i = start; i < dictionary.length; i++) {
      if (dictionary[i][1] == '')
        break;
      var reg = new RegExp(dictionary[i][1],'g');
      string = string.replace(reg,dictionary[i][0]);
      var now = new Date();
      if ((now - time_start) > 80) {
        setTimeout(function () {
          shared.compress(string,dictionary,callback,i+1,timer);
        },50);
        return;
      }
    }
    console.log("Compression took: ",((new Date()) - timer) / 1000,'s');
    callback.call({},string);
  },
  decompress: function (string,dictionary,callback,start,timer) {
    var time_start = new Date();
    if (!timer)
      timer = new Date();
    if (!start) {
      start = 0;
    }
    for (var i = start; i < dictionary.length; i++) {
      if (dictionary[i][1] == '')
        break;
      var reg = new RegExp(dictionary[i][0],'g');
      string = string.replace(reg,dictionary[i][1].replace('\\]',']').replace('\\[','['));
      var now = new Date();
      if ((now - time_start) > 80) {
        setTimeout(function () {
          shared.decompress(string,dictionary,callback,i+1,timer);
        },50);
        return;
      }
    }
    console.log("decompression took: ",((new Date()) - timer) / 1000,'s');
    callback.call({},string);
  },
  math: {
    between: function (needle,s1,s2) {
      s1 = parseInt(s1);
      s2 = parseInt(s2);
      needle = parseInt(needle);
      console.log(needle,s1,s2);
      if (needle >= s1 && needle <= s2) {
        console.log('returning true');
        return true;
      }
      return false;
    },
    rand: function (num) {
      if (!num) {
        num = 10000;
      }
      return Math.floor(Math.random() * num);
    },
    to_currency: function (number,separator,unit) {
      var match, property, integerPart, fractionalPart;
      var settings = {         precision: 2,
      unit: i18n.currency_unit,
      separator: i18n.decimal_separator,
      delimiter :'',
      precision: 2
      };
      if ( separator ) {
        settings.separator = separator;
      }
      if ( unit ) {
        settings.unit = unit;
      }
      match = number.toString().match(/([\+\-]?[0-9]*)(.[0-9]+)?/);
      
      if (!match) return;
      
      integerPart = match[1].replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1" + settings.delimiter);
      fractionalPart = match[2] ? (match[2].toString() + "000000000000").substr(1, settings.precision) : "000000000000".substr(1, settings.precision);
      
      return settings.unit + integerPart + ( settings.precision > 0 ? settings.separator + fractionalPart : "");
    },
    to_percent: function (number,separator) {
      unit = '%';
      var match, property, integerPart, fractionalPart;
      var settings = {         precision: 2,
      unit: i18n.currency_unit,
      separator: i18n.decimal_separator,
      delimiter :'',
      precision: 0
      };
      if ( separator ) {
        settings.separator = separator;
      }
      if ( unit ) {
        settings.unit = unit;
      }
      match = number.toString().match(/([\+\-]?[0-9]*)(.[0-9]+)?/);
      
      if (!match) return;
      
      integerPart = match[1].replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1" + settings.delimiter);
      fractionalPart = match[2] ? (match[2].toString() + "000000000000").substr(1, settings.precision) : "000000000000".substr(1, settings.precision);
      
      return '' + integerPart + ( settings.precision > 0 ? settings.separator + fractionalPart : "") + settings.unit;
    },
    to_float: function (str, returnString) {
      if (str == '' || !str) {return 0.0;}
      if (returnString == null) returnString = false;
      if (typeof str == 'number') {
        return shared.math.round(str);
      }
      if (str.match(/\d+\.\d+\,\d+/)) {
        str = str.replace('.','');
      }
      var ac = [0,1,2,3,4,5,6,7,8,9,'.',',','-'];
      var nstr = '';
      for (var i = 0; i < str.length; i++) {
        c = str.charAt(i);
        if (inArray(c,ac)) {
          if (c == ',') {
            nstr = nstr + '.';
          } else {
            nstr = nstr + c;
          }
        }
      }
      return (returnString) ? nstr : shared.math.round(parseFloat(nstr));
    }, // end to_float
    round: function (Number, DecimalPlaces) {
      if (!DecimalPlaces)
        DecimalPlaces = 2
        return Math.round(parseFloat(Number) * Math.pow(10, DecimalPlaces)) / Math.pow(10, DecimalPlaces);
    }
  },
  create: {
    plus_button: function (callback) {
      var button = create_dom_element('div',{class:'add-button'},'','');
      button.on('click',callback);
      return button;
    },
    finish_button: function (callback) {
      var button = create_dom_element('div',{class:'finish-button'},'','');
      button.on('click',callback);
      return button;
    }
  },
  draw: {
    /* returns a happy, centered dialog that you can use to display stuff */
    dialog: function (title,id,clear) {
      var dialog = shared.element('div',{id: id,class: 'salor-dialog'},'',$('body'));
      dialog.css({width: retail.container.width() * 0.50, height: retail.container.height() * 0.30,'z-index':11});
      
      if (_get('existed',dialog)) {
        dialog.html('');
        _set('existed',false,dialog);
      }
      var pad_div = create_dom_element('h2',{class: 'header'},title,dialog);
      dialog.append('<br /><hr />');
      deletable(dialog,function () { $(this).parent().remove()});
      shared.helpers.center(dialog, $(window));
      return dialog;
    },
    loading: function (predraw,align_to) { //we need to predraw this element if we can because it loads an asset
    if (!align_to) {
      align_to = $(window);
    }
    //console.log('showing loader');
    var loader = shared.element('div',{id: 'loader'},'',$('body'));    
    loader.show();
    shared.helpers.center(loader,align_to);
    _set('retail.loader_shown',true);
    _set('retail.show_loading',false);
    },
    hide_loading: function () {
      //console.log('hiding loader');
      var loader = shared.element('div',{id: 'loader'},'',$('body')); 
      loader.hide();
      _set('retail.loader_shown',false);
      _set('retail.show_loading',false);
    },
    option: function (name,append_to,callback,initval,type) {
      if (!initval)
        initval = '';
      var div = shared.element('div',{id: 'option_' + name,class:'options-row'}, '', append_to);
      div.append('<div class="option-name">' + name + '</div>');
      var div2 = shared.element('div',{class:'option-input'}, '', div);
      var input = shared.element('input',{id: 'option_' + name + '_input', type:'text',class:'option-actual-input'},'',div2);
      input.val(initval);
      input.on('keyup',callback);
      input.focus(shared.callbacks.on_focus);
      return div;
    },
    check_option: function (name,append_to,callback,initval) {
      if (!initval)
        initval = false;
      var div = shared.element('div',{id: 'option_' + name.replace(/\s/,''),class:'options-row'}, '', append_to);
      div.append('<div class="option-name">' + name + '</div>');
      var div2 = shared.element('div',{class:'option-input'}, '', div);
      var input = shared.element('input',{id: 'option_' + name.replace(/\s/,'') + '_input', type:'checkbox',class:'option-actual-input'},'',div2);
      input.attr('checked',initval);
      input.change(callback);
      input.checkbox();
      return div;
    },
    select_option: function (name,append_to,callback,initval) {
      if (!initval)
        initval = false;
      var div = shared.element('div',{id: 'option_' + name.replace(/\s/,''),class:'options-row'}, '', append_to);
      div.append('<div class="option-name">' + name + '</div>');
      var div2 = shared.element('div',{class:'option-input'}, '', div);
      
    },
  },
  helpers: {
    align: function (obj1,obj2,target1,target2) {
      if (!target1) {
        target1 = obj1;
      }
      if (!target2) {
        target2 = obj1;
      }
      if (obj1.outerWidth() > obj2.outerWidth()) {
        target2.css({'padding-left': obj1.outerWidth() - obj2.outerWidth()})
      } else {
        target1.css({'padding-left': obj2.outerWidth() - obj1.outerWidth()})
      }
    },
    pad: function (val,what,length,orientation) {
      val = val.toString();
      if (!orientation)
        orientation = 'left';
      while (val.length < length) {
        if (orientation == 'left')
          val = what + val;
        else
          val = val + what;
      }
      return val;
    },
    paginator: function (elem,result_func) {
      elem.find('.result').remove();
      if (!_get('start',elem)) {
        _set('start',0,elem);
      }
      if (result_func) {
        _set('result_func',result_func,elem);
      } else {
        result_func = _get('result_func',elem);
      }
      var start = _get('start',elem);
      var page_size = _get('page_size',elem);
      if (!page_size) {
        page_size = 5;
      }
      var results = _get('results',elem);
      var offset = elem.offset();
      console.log("paginating",start,page_size,results.length);
      var width = (elem.width() / 10);
      if (width > 35) {
        width = 35;
      }
      var left_tab = shared.element('div',{id: 'paginator_left_tab'},'<',elem);
      left_tab.css({height: (elem.height() / 3), width: width });
      left_tab.offset({left: offset.left - left_tab.outerWidth() + 5});
      if (!_get('existed',left_tab)) {
        left_tab.on('click',function () {
          var start = _get('start',$(this).parent());
          var next = start - page_size;
          if (next < 0) {
            next = 0;
          }
          _set('start',next,elem);
          shared.helpers.paginator(elem,result_func);
        });
      }
      
      var right_tab = shared.element('div',{id: 'paginator_right_tab'},'>',elem);
      right_tab.css({height: (elem.height() / 3), width: width });
      right_tab.offset({left: offset.left + elem.outerWidth() - 5});
      if (!_get('existed',right_tab)) {
        right_tab.on('click',function () {
          var start = _get('start',$(this).parent());
          var results = _get('results',elem);
          var next = start + page_size;
          if (next >= results.length) {
            next = start;
          }
          _set('start',next,elem);
          shared.helpers.paginator(elem,result_func);
        });
      }
      elem.find('.result-count').remove();
      elem.find('.header').append("<span class='result-count'>("+results.length+")</span>");
      
      for (var i = start; i < start + page_size; i++) {
        var obj = results[i];
        if (obj) {
          result_func.call(elem,obj);
        }
      }
    },
    merge: function (obj1,obj2) {
      if (obj1 == null)
        return obj2
      if (obj1 instanceof Object && obj2 instanceof Object) {
        for (var key in obj2) {
          if (obj1[key]) {
            if (obj1[key] instanceof Object && obj2[key] instanceof Object) {
              obj1[key] = shared.helpers.merge(obj1[key],obj2[key]);
            } else {
              obj1[key] = obj2[key];
            }
          } else {
            obj1[key] = obj2[key];
          }
        }
      } // end if
    return obj1;
    },
    to_inline_block: function (elem) {
      elem.css({position: 'relative', display: 'inline-block'});
      return elem;
    },
    expand: function (elem,amount,direction) {
      if (!direction)
        direction = 'both';
      if (direction == 'both' || direction == 'vertical') {
        elem.css({height: elem.outerHeight() + (elem.outerHeight() * amount)});
      }
      if (direction == 'both' || direction == 'horizontal') {
        elem.css({width: elem.outerWidth() + (elem.outerWidth() * amount)});
      }
    },
    shrink: function (elem,amount,direction) {
      if (!direction)
        direction = 'both';
      if (direction == 'both' || direction == 'vertical') {
        elem.css({height: elem.outerHeight() - (elem.outerHeight() * amount)});
      }
      if (direction == 'both' || direction == 'horizontal') {
        elem.css({width: elem.outerWidth() - (elem.outerWidth() * amount)});
      }
    },
    /* Center an element on the page, second argument is the element to center it to*/
    center: function (elem,center_to_elem,add_offset) {
      if (!center_to_elem)
        center_to_elem = $(window);
      var offset = center_to_elem.offset();
      if (!offset) {
        offset = {top: 0, left: 0};
      }
      var width = elem.outerWidth();
      var height = elem.outerHeight();
      var swidth = center_to_elem.width();
      var sheight = center_to_elem.height();
      sheight = Math.floor((sheight / 2) - (height / 2));  
      elem.css({position: 'absolute'});
      var ntop = offset.top + sheight;
      var nleft = offset.left + Math.floor((swidth / 2) - (width / 2));
      if (add_offset) {
        ntop += add_offset.top;
        nleft += add_offset.left;
      }
      var new_offset = {top: ntop, left: nleft};
      elem.offset(new_offset);
    }, //end center
    bottom_right: function (elem,center_to_elem) {
      var offset = center_to_elem.offset();
      offset.top += center_to_elem.height() - elem.outerHeight();
      offset.left += center_to_elem.width() - elem.outerWidth();
      elem.css({position: 'absolute'});
      elem.offset(offset);
    },
    top_left: function (elem,center_to_elem) {
      elem.css({position: 'absolute'});
      var offset = center_to_elem.offset();
      elem.offset(offset);
    },
    position_rememberable: function (elem) {
      var key = 'position_rememberable.' + elem.attr('id');
    var position = JSON.parse(localStorage.getItem(key));
    elem.css({position: 'absolute'});
    if (!position) {
      console.log('setting to offset');
      position = elem.offset();
      localStorage.setItem(key, JSON.stringify(position));
    } else {
      elem.offset(position);
    }
    elem.draggable({
      stop: function () {
        console.log('saving position',key,$(this).offset());
        localStorage.setItem(key, JSON.stringify($(this).offset()));
      }
    });
    }
  }, // end helpers
  callbacks: {
    on_focus: function () {
      $('.has-focus').removeClass('has-focus');
      $(this).addClass('has-focus');
     },
  },
  control: {
    task_manager: function (task_set) {
      var self = this;
      this._task_set = task_set;
      this.add = function (name,callback,priority,permanent,context) {
        for (var i = 0; i < self._task_set.length; i++) {
          if (self._task_set[i].name == name) {
            console.log('that task is already scheduled');
            return;
          }
        }
        var task = {
          name: name,
          callback: callback,
          priority: priority,
          is_permanent: permanent,
          context: context
        }
        self._task_set.push(task);
        self._task_set.sort(function (a,b) {
          if (a.priority < b.priority)
            return -1
          if (a.priority == b.priority)
            return 0
          if (a.priority > b.priority)
            return 1
        });
      }
      this.run = function () {
        console.log('TaskManager Runnging');
        var time_start = new Date();
        var times = self._task_set.length;
        for (var i = 0; i < times; i++) {
          t = self._task_set.reverse().pop();
          self._task_set.reverse();
          self.run_task(t);
          var now = new Date();
          if (now - time_start > 150) {
            return;
          }
        }
      }
      this.run_task = function (t) {
        console.log('calling',t);
        t.callback.call(t.context);
        if (t.is_permanent) {
          this._task_set.push(t);
        }
      }
    }
  },
} // end shared
        