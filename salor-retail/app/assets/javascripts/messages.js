var messagesHash = {'notices':[], 'alerts':[], 'prompts':[]};

function displayMessage(type, msg, id) {
  var statusbar = $("#messages");
  if ($("#" + id).length > 0) {
    $("#" + id).html(msg);
  } else {
    var statusmessage = $("<div></div>");
    statusmessage.html(msg);
    statusmessage.addClass("statusmessage");
    if (type == "notice") {
      statusmessage.addClass("message_notice");
    } else if (type == "alert") {
      statusmessage.addClass("message_alert");
    }
    if (typeof id == "undefined") {
      id = "notice_" + Math.floor((Math.random()*100000)+1);
    }
    statusmessage.attr("id", id);
    
    statusbar.prepend(statusmessage);
    statusmessage.fadeOut(5000, function() {
      $(this).slideUp(function() {
        $(this).remove();
      });
      
    });
  }
}

function displayMessages() {
  var notices = messagesHash['notices'];
  var alerts = messagesHash['alerts'];
  var prompts = messagesHash['prompts'];
  
  $.each(notices, function(idx) {
    var random_id = "message_" + Math.floor((Math.random()*10000)+1);
    displayMessage("notice", notices[idx], random_id);
  });
  
  $.each(alerts, function(idx) {
    var random_id = "message_" + Math.floor((Math.random()*10000)+1);
    displayMessage("alert", notices[idx], random_id);
  });
  
 
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
  
  messagesHash = {'notices':[], 'alerts':[], 'prompts':[]};
}

/*
function displayMessages() {
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
  
  messagesHash = {'notices':[], 'alerts':[], 'prompts':[]};
}
*/


function fadeMessages() {
  $('#messages').fadeIn(1000);
  setTimeout(function(){
    $('#messages').fadeOut(1000);
  }, 10000);
}