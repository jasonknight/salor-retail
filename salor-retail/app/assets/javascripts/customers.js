sr.fn.customers.removeNoteFields = function(link) {
  $(link).prev("input[type=hidden]").val("1");
  $(link).closest(".fields").hide();
}

sr.fn.customers.addNoteFields = function(link, association, content) {
  var new_id = new Date().getTime();
  var regexp = new RegExp("new_" + association, "g")
  $('#notes_row').after(content.replace(regexp, new_id));
}