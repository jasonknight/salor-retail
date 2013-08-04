var messagesHash = {'notices':[], 'alerts':[], 'prompts':[]};

function displayMessages() {
  console.log(messagesHash);
  var notices = messagesHash['notices'];
  var alerts = messagesHash['alerts'];
  var prompts = messagesHash['prompts'];
  if ( notices.length > 0 ) {
    $('#notices').html('<span>' + notices.join('</span><br /><span>') + '</span>');
  }
  if ( alerts.length > 0 ) {
    $('#alerts').html('<span>' + alerts.join('</span><br /><span>') + '</span>');
  }
  if ( prompts.length > 0 ) {
    $.each(prompts, function(i,o) {
      var dialog_id = 'prompt-dialog_' + i;
      var dialog = shared.draw.dialog('', dialog_id, o);
      var okbutton = shared.create.dialog_button('OK', function() {
        ajax_log({
          action_taken:'confirmed_prompt_dialog',
          called_from: o
        });
        dialog.remove();
      });
      dialog.append(okbutton);
    });
  }
  
  if (notices.length > 0 || alerts.length > 0) {
    fadeMessages();
  }
}


function fadeMessages() {
  $('#messages').fadeIn(1000);
  setTimeout(function(){
    $('#messages').fadeOut(1000);
  }, 10000);
}