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