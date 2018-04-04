
sr.data.session.other.container = $(window);

var shared = {
  element: function (tag,attrs,content,append_to) {
    if (attrs["id"] && $('#' + attrs["id"]).length != 0) {
      var elem = $('#' + attrs["id"]);
      _set('existed',true,elem);
      return elem;
    } else {
      return shared.create.domElement(tag,attrs,content,append_to)
    }
  },
  makeSelectWidget: function(name,elem) {
    var _currentSelectTarget = '';
    var _currentSelectButton;

    if (elem.children("option").length > 32) {
      return;
    }
    elem.hide();

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
      if ($('.select-widget-display').length > 0) {
        $('.select-widget-display').remove();
        return;
      }
      var mdiv = $('<div></div>');
      _currentSelectTarget = $(this).attr("select_target");
      _currentSelectButton = $(this);
      mdiv.addClass("select-widget-display select-widget-display-" + _currentSelectTarget.replace("#",""));
      var x = 0;
      $(_currentSelectTarget).children("option").each(function () {
        var d = $('<div id="active_select_'+$(this).attr('value').replace(':','-')+'"></div>');
        var label = $(this).text();
        if (label == "")
          label = "&nbsp;"
        d.html(label);
        d.addClass("select-widget-entry select-widget-entry-" + _currentSelectTarget.replace("#",""));
        d.attr("value", $(this).attr('value'));
        d.on("click", function () {
          $(_currentSelectTarget).find("option:selected").removeAttr("selected"); 
          $(_currentSelectTarget).find("option[value='"+$(this).attr('value')+"']").attr("selected","selected");
          $(_currentSelectTarget).find("option[value='"+$(this).attr('value')+"']").change(); 
          _currentSelectButton.html($(this).html());
          var input_id = _currentSelectTarget.replace("type","amount");
          setTimeout(function () { $(input_id).select(); },55);
          $('.select-widget-display').remove();
        });
        mdiv.append(d);
        x++;
        if (x == 4) {
          x = 0;
          mdiv.append("<br />");
        }

      });
      //mdiv.css({position: 'absolute'});
      $('body').append(mdiv);
      mdiv.css("left", sr.data.various.mouse_x)
      mdiv.css("top", sr.data.various.mouse_y)
      mdiv.on("click", function() {
        $(this).hide();
      });
    });
  },
  array_tools: {
    arrayCompare: function(a1, a2) {
      if (a1.length != a2.length) return false;
      var length = a2.length;
      for (var i = 0; i < length; i++) {
        if (a1[i] !== a2[i]) return false;
      }
      return true;
    },
    inArray: function(needle, haystack) {
      var length = haystack.length;
      for(var i = 0; i < length; i++) {
        if(typeof haystack[i] == 'object') {
          if(shared.array_tools.arrayCompare(haystack[i], needle)) return true;
        } else {
          if(haystack[i] == needle) return true;
        }
      }
      return false;
    },
  },
  scrolling_helpers: {
    scrollTo: function(element, speed) {
      sr.fn.debug.echo("SCROLLING");
      target_y = $(window).scrollTop();
      current_y = $(element).offset().top;
      if (sr.data.session.other.workstation) {
        shared.scrolling_helpers.doScroll((current_y - target_y)*1.05, speed);
      } else {
        window.scrollTo(0, current_y);
      }
    },
    scrollFor: function(distance, speed) {
      sr.fn.debug.echo("SCROLLING");
      shared.scrolling_helpers.doScroll(distance, speed);
    },
    doScroll: function(diff, speed) {
      sr.fn.debug.echo("SCROLLING");
      window.scrollBy(0,diff/speed);
      newdiff = (speed-1)*diff/speed;
      scrollAnimation = setTimeout(function(){
        do_scroll(newdiff, speed)
      }, 20);
      if ( Math.abs(diff) < 5 ) clearTimeout(scrollAnimation);
    },
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
    callback.call({},string);
  },
  math: {
    between: function (needle,s1,s2) {
      s1 = parseInt(s1);
      s2 = parseInt(s2);
      needle = parseInt(needle);
      if (needle >= s1 && needle <= s2) {
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
      unit: Region.number.currency.format.unit,
      separator: Region.number.currency.format.delimiter,
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
        if (shared.array_tools.inArray(c,ac)) {
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
    domElement: function(tag,attrs,content,append_to) {
      var element = $(document.createElement(tag));
      if ( typeof attrs.clss != 'undefined' ) {
        //class is a reserved word
        var cls = attrs['clss'];
        delete attrs.clss;
        element.addClass(cls);
      }
      $.each(attrs, function (k,v) {
        element.attr(k, v);
      });
      element.html(content);
      if (append_to != '') {
        $(append_to).append(element);
      }
      return element;
    },
    plus_button: function (callback) {
      var button = shared.create.domElement('div',{},'','');
      button.addClass('add-button');
      button.on('mousedown',callback);
      return button;
    },
    finish_button: function (callback) {
      var button = shared.create.domElement('div',{},'','');
      button.addClass('finish-button');
      button.on('mousedown',callback);
      return button;
    },
    dialog_button: function (caption, callback) {
      var button = shared.create.domElement('div',{},caption,'');
      button.addClass('dialog-button');
      button.on('mousedown',callback);
      return button;
    }
  },
  
  /* Adds a delete/X button to the element. Type options  are right and append. The default callback simply slides the element up. if you want special behavior on click, you can pass a closure.
   */
  makeDeletable: function(elem,type,callback) {
    if (typeof type == 'function') {
      callback = type;
      type = 'right'
    }
    if (!type)
      type = 'right';
    if ($('#' + elem.attr('id') + '_delete').length == 0) {
      var del_button = shared.create.domElement('div',{id: elem.attr('id') + '_delete', 'class':'delete', 'target': elem.attr('id')},'X',elem);
      if (!callback) {
        del_button.on('click',function () {
          $('#' + $(this).attr('target')).slideUp();
        });
      } else {
        del_button.on('click',callback);
      }
    } else {
      var del_button = $('#' + elem.attr('id') + '_delete');
      if (callback) {
        del_button.unbind('click').on('click',callback);
      }
    }
    var offset = elem.offset();
    if (type == 'right') {
      offset.left += elem.outerWidth() - del_button.outerWidth() - 5;
      offset.top += 5
      del_button.offset(offset);
    } else if (type == 'append') {
      elem.append(del_button);
    }
    
  },
  
  draw: {
    /* returns a happy, centered dialog that you can use to display stuff */
    dialog: function (title,id,text,clear) {
      var dialog = shared.element('div',{id: id},'',$('body'));
      dialog.addClass('salor-dialog');
      dialog.css({
        width: sr.data.session.other.container.width() * 0.50,
        height: sr.data.session.other.container.height() * 0.40,
        'z-index':150
      });
      if (_get('existed',dialog)) {
        dialog.html('');
        _set('existed',false,dialog);
      }
      var pad_div = shared.create.domElement('h2',{},title,dialog);
      dialog.append('<hr />');
      pad_div.addClass('header');
      var contents = shared.create.domElement('div',{},text,dialog);
      contents.addClass('contents');
      shared.makeDeletable(dialog,function () { $(this).parent().remove()});
      shared.helpers.center(dialog, $(window));
      return dialog;
    },
    loading: function (predraw, align_to, append_to) { //we need to predraw this element if we can because it loads an asset
      var loader = shared.element('div',{id: 'loader'},'', append_to);  
      loader.css({
        'background-image':'url(/assets/loader.gif)',
        'background-repeat':'no-repeat',
        'background-position':'center,center',
        'background-size':'100%,100%',
        'position':'fixed',
        'width':'30%',
        'height':'10%',
        'z-index':151,
        'display':'none'
      });
      if (align_to) {
        shared.helpers.center(loader,align_to);
      }
      
      
      _set('retail.loader_shown',true);
      _set('retail.show_loading',false);
      return loader;
    },
    hide_loading: function () {
      var loader = shared.element('div',{id: 'loader'},'',$('body')); 
      loader.hide();
      _set('retail.loader_shown',false);
      _set('retail.show_loading',false);
    },
    option: function (options,callbacks) {
      if (!options.value)
        options.value = '';
      var div = shared.element('div',{id: 'option_' + options.name}, '', options.append_to);
      div.addClass('options-row');
      div.append('<div class="option-name">' + options.title + '</div>');
      var div2 = shared.element('div',{}, '', div);
      div2.addClass('option-input');
      var input = shared.element('input',{id: 'option_' + options.name + '_input', type:'text'},'',div2);
      input.on("click",function () {
        var inp = $(this);
        setTimeout(function () {
          inp.select();
        },55);
      });
      input.addClass('option-actual-input');
      var div3 = shared.element('div',{id: 'option_' + options.name + '_button'}, i18n.menu.ok, div);
      div3.addClass('option-button');
      div3.on("click",callbacks.click);
      input.val(options.value);
      input.on('keyup',callbacks.keyup);
      input.focus(callbacks.focus);
      input.blur(callbacks.blur);
      if ( typeof callbacks.keypress != 'undefined' ) {
        input.keypress(function(e) {
          callbacks.keypress(e);
        });
      }
      return div;
    },
    check_option: function (options,callbacks) {
      var div = shared.element('div',{id: 'option_' + options.name.replace(/\s/,'')}, '', options.append_to);
      div.addClass('options-row');
      div.append('<div class="option-name">' + options.title + '</div>');
      var div2 = shared.element('div',{}, '', div);
      div2.addClass('option-input');
      var input = shared.element('input',{id: 'option_' + options.name.replace(/\s/,'') + '_input', type:'checkbox'},'',div2);
      input.addClass('option-actual-input');
      input.attr('checked',options.value);
      input.change(callbacks.change);
      input.checkbox();
      return div;
    },
    select_option: function (options) {
      var div = shared.element('div',{id: 'option_' + options.name.replace(/\s/,'')}, '', options.append_to);
      div.addClass('options-row');
      div.append('<div class="option-name">' + options.title + '</div>');
      var div2 = shared.element('div',{}, '', div);
      div2.addClass('option-input option-select-input');
      for (var i = 0; i < options.selections.length; i++) {
        var selection = options.selections[i];
        var select = shared.element('select',{id: 'option_' + selection.name.replace(/\s/,'') + '_' + i},'',div2);
        select.addClass('option-actual-input');
        for (var attr in selection.attributes) {
          select.attr(attr,selection.attributes[attr]);
        }
        shared.element('option',{value: ''},i18n.views.single_words.choose,select);
        for (var key in selection.options) {
          var opt = shared.element('option',{value: key},selection.options[key],select);
          if (selection.value == key) {
            opt.attr('selected',true);
          }
        }
        select.on('change',selection.change);
      }
      return div;
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
      var width = (elem.width() / 10);
      if (width > 35) {
        width = 35;
      }
      var left_tab = shared.element('div',{id: 'paginator_left_tab'},'<',elem);
      left_tab.css({height: (elem.height() / 3), width: width });
      left_tab.offset({left: offset.left - left_tab.outerWidth() + 5});
      if (!_get('existed',left_tab)) {
        left_tab.on('mousedown',function () {
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
        right_tab.on('mousedown',function () {
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
    bottom_right: function (elem,center_to_elem,pad) {
      var offset = center_to_elem.offset();
      offset.top += center_to_elem.height() - elem.outerHeight();
      offset.left += center_to_elem.width() - elem.outerWidth();
      if (pad) {
        offset.top += pad.top;
        offset.left += pad.left;
      }
      elem.css({position: 'absolute'});
      elem.offset(offset);
    },
    top_left: function (elem,center_to_elem,pad) {
      elem.css({position: 'absolute'});
      var offset = center_to_elem.offset();
      if (pad) {
        offset.top += pad.top;
        offset.left += pad.left;
      }
      elem.offset(offset);
    },
    top_right: function (elem,center_to_elem,pad) {
      elem.css({position: 'absolute'});
      var offset = center_to_elem.offset();
      offset.left += center_to_elem.width() - elem.outerWidth();
      if (pad) {
        offset.top += pad.top;
        offset.left += pad.left;
      }
      elem.offset(offset);
    },
    position_rememberable: function (elem) {
      var key = 'position_rememberable.' + elem.attr('id');
      var position = JSON.parse(localStorage.getItem(key));
      elem.css({position: 'absolute'});
      if (!position) {
        position = elem.offset();
        localStorage.setItem(key, JSON.stringify(position));
      } else {
        elem.offset(position);
      }
      elem.draggable({
        stop: function () {
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
        t.callback.call(t.context);
        if (t.is_permanent) {
          this._task_set.push(t);
        }
      }
    }
  },
}
