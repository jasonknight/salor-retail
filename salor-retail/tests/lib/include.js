env.include = function (file_path) {
  var contents = IO.read(file_path);
  env.evaluate(contents,file_path);
}
