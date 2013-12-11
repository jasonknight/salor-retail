sr.fn.debug.echo = function(str) {
  if ( sr.fn.salor_bin.is() && typeof Salor.echo != 'undefined' ) {
    Salor.echo(str);
  } else if (typeof console != 'undefined') {
    console.log(str);
  }
}

sr.fn.debug.ajaxLog = function(data) {
  $.ajax({
    url:'/orders/log',
    type:'post',
    data: data
  });
}

sr.fn.debug.sendEmail = function(subject, message) {
  console.log('send_email:', subject, message);
  message += "\n\nuser login: " + sr.data.session.user.username;
  message += "\n\n" + navigator["userAgent"];
  $.ajax({
    type: 'post',
    url:'/session/email',
    data: {
      s:subject,
      m:message
    }
  });
}