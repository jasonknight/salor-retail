sr.fn.user_logins.display = function() {
  if (User.role_cache.indexOf('manager') != -1) {
    try {
      var lin = $('.user_login_time');
      var lout = $('.user_logout_time');
      lin.datetimepicker(
        {
          timeFormat: 'HH:mm:ss',
          dateFormat: 'yy-mm-dd',
          onSelect: function (dateTimeText,picker) {
            
            var string = '/vendors/edit_field_on_child?id=' +
            $(picker.$input).attr('model_id') +'&klass=UserLogin' +
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
                  
                  var string = '/vendors/edit_field_on_child?id=' +
                  $(picker.$input).attr('model_id') +'&klass=UserLogin' +
                  '&field=logout'+
                  '&value=' + dateTimeText;
                  $.get(string);
                }
              }
      );
    } catch (e) { var e = '';}
  } // if user.role_cache
}