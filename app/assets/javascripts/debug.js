function dbg(obj) {
  var str = '';
  alert(obj.width);
  for (var prop in obj) {
    str = str + " " + prop + ":" +obj[prop];
  }
  alert(str);
}

function clog() {
  try {
    if (typeof Salor != 'undefined') {
        // i.e. Salor object is only defined when we are inside of salor gui...
    } else {
      console.log(arguments);
    }
  } catch(e){
  }
}
