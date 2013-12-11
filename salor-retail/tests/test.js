var view = new Chrome();
view.load("http://google.com");
view.p_inner_object.FinishedLoadingSignal.connect(function () {
  //print("hello world");
  setTimeout(function () {
  sendText(view,"hello"); },100);
});
