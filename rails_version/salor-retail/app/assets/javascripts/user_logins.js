sr.fn.user_logins.display = function() {
  if (sr.data.session.user.role_cache.indexOf('manager') != -1) {
    try {
      var lin = $('.user_login_time');
      var lout = $('.user_logout_time');
      lin.datetimepicker(
        {
          timeFormat: 'HH:mm:ss',
          dateFormat: 'yy-mm-dd',
          onSelect: function (dateTimeText,picker) {
            var mid = $('#' + picker.id).attr('model_id');
            if ( ! mid ) {
              mid = $(picker.$input).attr('model_id')
            }

            //console.log("MID IS: ", mid)

            var string = '/vendors/edit_field_on_child?id=' +
            mid +'&klass=UserLogin' +
            '&field=login'+
            '&value=' + dateTimeText;
            $.get(string);
          }
        }
        );
        lout.datetimepicker(
          {
            timeFormat: 'HH:mm:ss',
            dateFormat: 'yy-mm-dd',
            onSelect: function (dateTimeText,picker) {
              var mid = $('#' + picker.id).attr('model_id');
              if ( ! mid ) {
                mid = $(picker.$input).attr('model_id')
              }

              //console.log("MID IS: ", mid)
              var string = '/vendors/edit_field_on_child?id=' +
              mid +'&klass=UserLogin' +
              '&field=logout'+
              '&value=' + dateTimeText;
              $.get(string);
            }
          }
      );
    } catch (e) { var e = '';}
  } // if user.role_cache
}

sr.fn.user_logins.showPopup = function() {
  var el = $("#simple_input_dialog").dialog({
    modal: false,
    buttons: {
      "Cancel": function() {
        var bValid = true;
        $('#dialog_input').removeClass("ui-state-error");
        updateTips("");
        bValid = bValid && checkLength($('#dialog_input'),"password",3,255);
        if (bValid) {            
            jQuery.post("/users/clockout",{password: $('#dialog_input').val()},function (data,textStatus,jqHXR) {
              if (data == "NO") {
                updateTips("Wrong Password");
              } else {
                $("#simple_input_dialog").dialog( "close" );
              }
            }).fail(function () {
              updateTips("Login to server failed due to server error, call tech support!");
            });
        } // end if bValid
      }, // end of cancel
      "Complete": function () {
        var bValid = true;
        $('#dialog_input').removeClass("ui-state-error");
        updateTips("");
        bValid = bValid && checkLength($('#dialog_input'),"password",3,255);
        if (bValid) {            
            jQuery.post("/users/clockin",{password: $('#dialog_input').val()},function (data,textStatus,jqHXR) {
              if (data == "NO") {
                updateTips("Wrong Password");
              } else if (data == "ALREADY") {
                updateTips("You are already clocked in!");
              } else {
                $("#simple_input_dialog").dialog( "close" );
              }
            }).fail(function () {
              updateTips("Login to server failed due to server error, call tech support!");
            });
        } // end if bValid
      }, // end of Complete
    } // end of buttons
  }); // end dialog

  setTimeout(function () {
    try {
    $('#dialog_input').val("");
    $(".ui-dialog * button > span:contains('Complete')").text(i18n.system.login);
    $(".ui-dialog * button > span:contains('Cancel')").text(i18n.system.logout);
    $('#dialog_input').keyup(function (event) {
      if (event.which == 13) {
        $(".ui-dialog * button:contains('"+i18n.system.login+"')").trigger("click");
      }
    });
    sr.fn.focus.set($('#dialog_input'));
    var ttl = el.parent().find('.ui-dialog-title');
    ttl.html(i18n.system.login); 
    ttl = el.parent().find('.input_label');
    ttl.html(i18n.activerecord.attributes.password);
    } catch (err) {
      console.log(err);
    }
  },55);
}