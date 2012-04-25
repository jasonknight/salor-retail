setInterval("$.ajax('/home/get_connection_status');", 5000);

$(function(){
  $('#service_connect_password').select();
})

function connect_service(type) {
  $('img#progress').show();
  host = $('#service_connect_host').val();
  user = $('#service_connect_user').val();
  password = $('#service_connect_password').val();
  $.get('/home/connect_remote_service', {pw: password, host: host, user: user, type: type} );
}
