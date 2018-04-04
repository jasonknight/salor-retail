env.help = {}
var modules = IO.dir("doc");
for (var i = 0; i < modules.length; i++) {
  var module = modules[i];
  if (module.name != "." && module.name != ".." && module.isDir == true) {
    env.help[module.name] = {};
    __get_files_as_hash(module.path,env.help[module.name]);
  }
}
function __get_files_as_hash(path,append_to) {
  var entries = IO.dir(path);
  for (var i = 0; i < entries.length; i++) {
    var entry = entries[i];
    var name = entry.name.replace('.txt','');
    var path = entry.path;
    if (entry.name == "." || entry.name == "..") {
      continue;
    }
    if (entry.isDir == true) {
      append_to[name] = {};
      __get_files_as_hash(path,append_to[name]);
      
    } else {
      
      var text = IO.read(path);
      append_to[name] = text;
//       append_to[name] = IO.read(entry.path);
    }
  }
}
