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