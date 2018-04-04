sr.fn.messages.displayMessage = function(type, msg, id) {
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
    setTimeout(function() {
      statusmessage.slideUp(1000);
    }, 4000);
  }
}

sr.fn.messages.displayMessages = function() {
  var notices = sr.data.messages.notices;
  var alerts = sr.data.messages.alerts;
  var prompts = sr.data.messages.prompts;
  
  $.each(notices, function(idx) {
    var random_id = "message_" + Math.floor((Math.random()*10000)+1);
    sr.fn.messages.displayMessage("notice", notices[idx], random_id);
  });
  
  $.each(alerts, function(idx) {
    var random_id = "message_" + Math.floor((Math.random()*10000)+1);
    sr.fn.messages.displayMessage("alert", alerts[idx], random_id);
  });
  
  $.each(prompts, function(i,o) {
    var dialog_id = 'prompt-dialog_' + i;
    var dialog = shared.draw.dialog('', dialog_id, o);
    var okbutton = shared.create.dialog_button('OK', function() {
      sr.fn.debug.ajaxLog({
        action_taken:'confirmed_prompt_dialog',
        called_from: o,
      });
      dialog.remove();
    });
    dialog.append(okbutton);
  });
  
  sr.data.messages.notices = [];
  sr.data.messages.alerts = [];
  sr.data.messages.prompts = [];
}


sr.fn.messages.fadeMessages = function() {
  $('#messages').fadeIn(1000);
  setTimeout(function(){
    $('#messages').fadeOut(1000);
  }, 10000);
}