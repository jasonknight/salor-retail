function echo(str) {
  if ( isSalorBin() && typeof Salor.echo != 'undefined' ) {
    Salor.echo(str);
  } else if (typeof console != 'undefined') {
    console.log(str);
  }
}

function ajax_log(data) {
  $.ajax({
    url:'/orders/log',
    type:'post',
    data: data
  });
}

function send_email(subject, message) {
  console.log('send_email:', subject, message);
  message += "\n\nuser login: " + User.username;
  message += "\n\n" + navigator["userAgent"];
  $.ajax({
    type: 'post',
    url:'/session/email',
    data: {s:subject, m:message}
  })
}