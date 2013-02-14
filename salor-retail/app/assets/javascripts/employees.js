$(function () {
  if (User.role_cache.indexOf('manager') != -1) {
    var lin = $('.employee_login_time');
    var lout = $('.employee_logout_time');
    lin.datetimepicker(
      {
        timeFormat: 'HH:mm:ss',
        dateFormat: 'yy/mm/dd',
        onSelect: function (dateTimeText,picker) {

          var string = '/vendors/edit_field_on_child?id=' +
          $(picker.$input).attr('model_id') +'&klass=EmployeeLogin' +
          '&field=login'+
          '&value=' + dateTimeText;
          $.get(string);
        }
      }
    );
    lout.datetimepicker(
      {
        timeFormat: 'HH:mm:ss',
        dateFormat: 'yy/mm/dd',
        onSelect: function (dateTimeText,picker) {
          
          var string = '/vendors/edit_field_on_child?id=' +
          $(picker.$input).attr('model_id') +'&klass=EmployeeLogin' +
          '&field=logout'+
          '&value=' + dateTimeText;
          $.get(string);
        }
      }
    );
  } // if user.role_cache
});

function remove_employee_login(thetd) {
  var thetr = $(thetd).closest("tr")
}