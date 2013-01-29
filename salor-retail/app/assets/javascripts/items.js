function itemsAddNameTranslation(locale) {
  var tdiv = shared.element('div',{id: 'name_translation_' + locale},'',$('#name_translations'));
  if (_get('existed',tdiv)) {
    return;
    
  }
  var label = shared.element('label',{id: 'name_translation_'+locale+'_label'},locale + ": &nbsp;",tdiv);
  var inp = shared.element('input',{name: 'item[name_translations]['+locale+']',type: 'text', class:'keyboardable'},'',label);
  inp.css({width: '50%'});
  return inp;
}
function remove_item_shipper_fields(link) {
  $(link).prev("input[type=hidden]").val("1");
  $(link).closest(".fields").hide();
}

function add_item_shipper_fields(link, association, content) {
  var new_id = new Date().getTime();
  var regexp = new RegExp("new_" + association, "g");
  content = content.replace("new_item_shipper_id","new_item_shipper_" + new_id);
  $('#item_shippers_hook').after(content.replace(regexp, new_id));
  var elem = $("#item_item_shippers_attributes_"+new_id+"_shipper_id");
  make_select_widget("Shipper Id",elem);
}