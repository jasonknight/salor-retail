env.modules.SetCalculateTax = function () {
  var self = this;
  this.state = 0;
  this.interval = 1200;
  this.interval_id = null;
  this.next_func = null;
  this.tries = 0;
  this.run = function (start_url) {
    if (start_url != "") {
      self.view.load(start_url);
    }
    self.interval_id = setInterval(self.event_loop,self.interval);
    return self;
  } // end run
  this.next = function (next_func) {
    self.next_func = next_func;
  }
  
  this.event_loop = function () {
    print("SetCalculateTax Beginning. State: " + self.state + "\n");
    switch(self.state) {
      case 0:
        if (self.view.ready()) {
          self.state++;
        }
        break;
      default:
        clearInterval(self.interval_id);
        if (self.next_func) {
          setTimeout(function () {
            self.next_func.call(self);
          },100);
        } 
        break;
    } // end switch self.state
  } // end event_loop
}
