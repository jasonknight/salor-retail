env.modules = {};
env.getType = function (obj) {
  if (obj.constructor == String) {
    return "String";
  } else if (obj.constructor == Array) {
    return "Array";
  } else if (obj.constructor == Function) {
    return "Function";
  } else if (obj.constructor == Number) {
    return "Number";
  } else if (obj.constructor == Object) {
    return "Object";
  } else if (obj.constructor == Boolean) {
    return "Boolean";
  } else {
    return (typeof obj);
  } 
}
env.failures = 0;
env.failures_messages = [];
env.fail = function (msg) {
  print("# ------------------------------------- #");
  print("# " + msg + "\n");
  print("# ------------------------------------- #");
  env.failures_messages.push(msg);
  env.failures++;
}
env.fatal = function (msg) {
  fail(msg);
  exit();
}
env.report_and_exit = function () {
  env.report();
  exit();
}
env.report = function () {
  print("# ------------------------------------- #");
  print("# Failures: " + env.failures);
  for (var i = 0; i < env.failures; i++) {
    print("# " + env.failures_messages[i] + "");
  }
  print("# ------------------------------------- #");
}
env.dump = function (object,depth) {
  if (!depth)
    depth = 0;
  var pad = '';
  for (var i = 0; i < depth; i++) {
    pad += "\t"
  }
  var text = pad + "{\n";
  for (var key in object) {
    if (typeof object[key] == 'object') {
      text += pad + "\t" + key + "(" + (typeof object[key]) + "): " + dump(object[key],depth + 1);
    } else {
      var value = object[key] + '';
      text += pad + "\t" + key + "(" + (typeof object[key]) + "): '" + value.replace("\n","\n" + pad) + "'\n";
    }
  }
  text += pad + "}\n";
  return text;
}
env.sendText = function (target,text) {
  if (target.p_inner_object) { target = target.p_inner_object;}
  try {
    env.p_sendText(target,text);
  } catch (err) {
    print("Send error: " + err);
  }
}

env.sendKey = function (target,key) {
  if (target.p_inner_object) { target = target.p_inner_object;}
  pKeyPress(target,key);
  setTimeout( function () {
    pKeyRelease(target,key);
  },10);
}

var Content = function (view) {
  var self = this;
  this.view = view;
  this._content = '';
  this.has = function (text) {
    var ret = false;
    if (self._content != '') {
      ret = (self._content.indexOf(text) != -1);
      self._content = '';
    } else {
      ret = (self.view.GetContent().indexOf(text) != -1);
    }
    return ret;
  }
  this.of = function (id) {
    self._type = "Element["+id+"]";
    self._content = self.view.GetContentOfElement(id);
    return self;
  }
}
