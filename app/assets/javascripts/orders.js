//= require paylife 
function getByCardAmount() {
  var val = 0;
  $(".payment-method").each(function () {
    var id = $(this).attr("id").replace("type","amount");
    if ($(this).val() == "ByCard") {
        val = $('#' + id).val();
    }
  });
  return val;
}
function paylifeWriteData(str) {
  alert("Sending data:: " + str)
  Salor.cuteWriteData(str);
}
function paylifePoleWrite(text) {
  if (typeof Salor != 'undefined' && window.Register.pole_display != '') {
      Salor.poleDancer(window.Register.pole_display, text );
  }
}
$(function () {
  if (typeof Salor != 'undefined') {
    Salor.cuteDataRead.connect(window.paylifeDataRead);
  }
});
