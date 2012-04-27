$(function(){
  if (typeof(Salor) != 'undefined') {
    $('#service_connect_password').select();
    setInterval("get_connection_status()", 5000);
  } else {
    $('#request_service').html(i18n_not_supported_by_browser);
  }
})

function get_connection_status(){
  if (typeof(Salor) != 'undefined') {
    ssh_connected = Salor.remoteServiceConnectionOpen('ssh');
    vnc_connected = Salor.remoteServiceConnectionOpen('vnc');
    if ( ssh_connected == false && vnc_connected == false ) {
      $('#connection_status').fadeOut(function(){
        $('#connection_status').css('background', '#CC5757');
        $('#connection_status').html(i18n_disconnected);
        $('#connect_service_vnc').fadeIn();
        $('#connect_service_ssh').fadeIn();
        $('#connection_status').fadeIn();
      });
    } else if ( ssh_connected && ! vnc_connected ) {
      $('#connection_status').fadeOut(function(){
        $('#connection_status').css('background', '#3c8522');
        $('#connection_status').fadeIn();
        $('#connect_service_vnc').fadeIn();
        $('#connect_service_ssh').fadeOut();
        $('#connection_status').html(i18n_connected);
      });
    } else if ( ! ssh_connected && vnc_connected ) {
      $('#connection_status').fadeOut(function(){
        $('#connection_status').css('background', '#418dc8');
        $('#connection_status').fadeIn();
        $('#connect_service_vnc').fadeOut();
        $('#connect_service_ssh').fadeIn();
        $('#connection_status').html(i18n_connected);
      });
    } else if ( ssh_connected && vnc_connected ) {
      $('#connection_status').fadeOut(function(){
        $('#connection_status').css('background', '#F6AF47');
        $('#connection_status').fadeIn();
        $('#connect_service_vnc').fadeOut();
        $('#connect_service_ssh').fadeOut();
        $('#connection_status').html(i18n_connected);
      });
    }
  }
  $('img#progress').hide();
}



function connect_service(type) {
  $('img#progress').show();
  host = $('#service_connect_host').val();
  user = $('#service_connect_user').val();
  password = $('#service_connect_password').val();
  if (typeof(Salor) != 'undefined') {
    if (type == 'ssh' && Salor.remoteServiceConnectionOpen('ssh') == false) {
      Salor.remoteService(host,user,password,'ssh');
    }
    if (type == 'vnc' && Salor.remoteServiceConnectionOpen('vnc') == false) {
      Salor.remoteService(host,user,password,'ssh');
    }
  }
}
