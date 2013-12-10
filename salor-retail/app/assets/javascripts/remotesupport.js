/*
Copyright (c) 2012 Red (E) Tools Ltd.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

sr.fn.remotesupport.setup = function() {
  $('#service_connect_password').select();
  setInterval("sr.fn.remotesupport.getStatus()", 4000);
}

sr.fn.remotesupport.getStatus = function(){
  $.ajax({
    url: "/session/update_connection_status",
    dataType: 'script'
  });
  ssh_connected = connection_status.ssh;
  vnc_connected = connection_status.vnc;
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
  $('img#progress').hide();
}

sr.fn.remotesupport.connect = function(type) {
  $('img#progress').show();
  host = $('#service_connect_host').val();
  user = $('#service_connect_user').val();
  password = $('#service_connect_password').val();
  if(type == 'ssh') {
    $.ajax({
      url: "/session/connect_remote_service",
      data: {type:'ssh', host:host, user:user, pw:password}
    });
  } else if (type == 'vnc') {
    $.ajax({
      url: "/session/connect_remote_service",
      data: {type:'vnc', host:host, user:user, pw:password}
    });
  }
}
