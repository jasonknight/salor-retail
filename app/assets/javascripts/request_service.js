setInterval("$.ajax('/home/get_connection_status');", 5000);

$(function(){
  $('#service_connect_password').select();
})

function connect_service() {
  $('img#progress').show();
  password = $('#service_connect_password').val();
  $.get('/home/connect_remote_service', {pw: password} );
}
