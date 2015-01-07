function render_translation_inputs(depth, ancestor_keys, tree, el) {
  
  for(var k in tree){
    var v = tree[k];
    if (typeof v == 'object') {
      var li = $(document.createElement('li'));
      li.html(k);
      el.append(li);
      var ul = $(document.createElement('ul'));
      el.append(ul);
      ancestor_keys.push(k);
      render_translation_inputs(depth+1, ancestor_keys, v, ul);
      ancestor_keys.pop();
    } else {
      var li = $(document.createElement('li'));
      var keyspan = $(document.createElement('span'));
      keyspan.html(k);
      
      var valinput = $(document.createElement('input'));
      valinput.attr('ancestor_keys', ancestor_keys + ',' + k);
      valinput.val(v);
      valinput.on('change', function(){
        submit_translation($(this));
      })
      valinput.on('click', function(){
        $(this).css('background-color', 'white');
      })

      li.append(keyspan);
      li.append(valinput);
      el.append(li);
    }
  }
}

function submit_translation(el) {
  el.css('background-color', '#99FF99');
  $.ajax({
    type: 'put',
    url: '/translations/set',
    data: {
      k: el.attr('ancestor_keys'),
      v: el.val(),
      f: translation_file,
    }
  })
}