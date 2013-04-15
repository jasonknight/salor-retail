env.Hessian = function (name) {
  var self = this;
  this.name = name;
  this.p_inner_object = Factory.GetHessian(name);
  this.content = new Content(this.p_inner_object);
  var nkey = '';
  for (var key in this.p_inner_object) {
    nkey = key.charAt(0).toLowerCase() + key.slice(1);
    nkey = nkey.replace(/\(.*\)/,'');
    this[nkey] = this.p_inner_object[key];
  }
  this.center = function () {
    var screen = window().geometry;
    var hgeo = self.getGeometry();
    var ny = (screen.height * 0.50) - (hgeo.height * 0.50);
    var nx = (screen.width * 0.50) - (hgeo.width * 0.50);
    self.move(nx,ny);
  }
  this.topLeft = function () {
    self.move(5,5);
  }
  this.bottomLeft = function () {
    var screen = window().geometry;
    var hgeo = self.getGeometry();
    var ny = screen.height - hgeo.height;
    var nx = 5;
    self.move(nx,ny);
  }
  this.topRight = function () {
    var screen = window().geometry;
    var hgeo = self.getGeometry();
    var ny = 5;
    var nx = screen.width - hgeo.width;
    self.move(nx,ny);
  }
  this.bottomRight = function () {
    var screen = window().geometry;
    var hgeo = self.getGeometry();
    var ny = screen.height - hgeo.height;
    var nx = screen.width - hgeo.width;
    self.move(nx,ny);
  }
  this.resize = function (w,h) {
    var geo = self.getViewGeometry();
    self.setViewGeometry({x:geo.x,y:geo.y,width: w, height: h});
  }
}
env.iPhone5 = function () {
  var h = new Hessian("iPhone5");
  h.createView();
  h.show();
  h.getPage().SetUserAgent("Mozilla/5.0 (iPhone; CPU iPhone OS 5_1 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9B179 Safari/7534.48.3");
  h.setViewGeometry({x:100,y:100,width: 700, height: 400});
  return h;
}
env.iPodTouch5 = function () {
  var h = new Hessian("iPodTouch5");
  h.createView();
  h.show();
  h.getPage().SetUserAgent("Mozilla/5.0 (iPod; CPU iPhone OS 5_1 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9B176 Safari/7534.48.3");
  return h;
}
env.iPad5 = function () {
  var h = new Hessian("iPodTouch5");
  h.createView();
  h.show();
  h.getPage().SetUserAgent("Mozilla/5.0 (iPad; CPU OS 5_1 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9B176 Safari/7534.48.3");
  return h;
}
env.Safari6 = function () {
  var h = new Hessian("Safari 6.0 Mac");
  h.createView();
  h.show();
  h.getPage().SetUserAgent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_4) AppleWebKit/536.25 (KHTML, like Gecko) Version/6.0 Safari/536.25");
  return h;
}
env.Safari5 = function () {
  var h = new Hessian("Safari 5.1 Windows");
  h.createView();
  h.show();
  h.getPage().SetUserAgent("Mozilla/5.0 (Windows; Windows NT 6.1) AppleWebKit/534.57.2 (KHTML, like Gecko) Version/5.1.7 Safari/534.57.2");
  return h;
}
env.IE7 = function () {
  var h = new Hessian("Internet Explorer 7");
  h.createView();
  h.show();
  h.getPage().SetUserAgent("Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0)");
  return h;
}
env.IE8 = function () {
  var h = new Hessian("Internet Explorer 8");
  h.createView();
  h.show();
  h.getPage().SetUserAgent("Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.0; Trident/4.0)");
  return h;
}
env.IE9 = function () {
  var h = new Hessian("Internet Explorer 9");
  h.createView();
  h.show();
  h.getPage().SetUserAgent("Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)");
  return h;
}
env.IE9 = function () {
  var h = new Hessian("Internet Explorer 9");
  h.createView();
  h.show();
  h.getPage().SetUserAgent("Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)");
  return h;
}
env.Chrome = function (name) {
  if ( ! name ) { name = "Chrome 19 Windows"; }
  var h = new Hessian(name);
  h.createView();
  h.show();
  h.getPage().SetUserAgent("Mozilla/5.0 (Windows; Windows NT 6.1) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.1084.46 Safari/536.5");
  return h;
}
env.ChromeMac = function () {
  var h = new Hessian("Chrome 19 Mac");
  h.createView();
  h.show();
  h.getPage().SetUserAgent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_4) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.1084.46 Safari/536.5");
  return h;
}
env.Firefox = function () {
  var h = new Hessian("Firefox Windows");
  h.createView();
  h.show();
  h.getPage().SetUserAgent("Mozilla/5.0 (Windows NT 6.1; rv:11.0) Gecko/20100101 Firefox/11.0");
  return h;
}
env.FirefoxMac = function () {
  var h = new Hessian("Firefox Mac");
  h.createView();
  h.show();
  h.getPage().SetUserAgent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:11.0) Gecko/20100101 Firefox/11.0");
  return h;
}
env.Opera = function () {
  var h = new Hessian("Opera Windows");
  h.createView();
  h.show();
  h.getPage().SetUserAgent("Opera/9.80 (Windows NT 6.1; U; en) Presto/2.10.229 Version/11.62");
  return h;
}
env.OperaMac = function () {
  var h = new Hessian("Opera Mac");
  h.createView();
  h.show();
  h.getPage().SetUserAgent("Opera/9.80 (Macintosh; Intel Mac OS X 10.7.4; U; en) Presto/2.10.229 Version/11.62");
  return h;
}
