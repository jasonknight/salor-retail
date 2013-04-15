env.modules.LoginMachine = function () {
  var self = this;
  this.state = 0;
  this.interval = 150;
  this.interval_id = null;
  this.view = null;
  this.next_func = null;
  this.run = function (start_url) {
    self.view.load(start_url);
    self.view.resize(1024,768);
    self.view.center();
    self.interval_id = setInterval(self.event_loop,self.interval);
    return self;
  }
  this.next = function (next_func) {
    self.next_func = next_func;
  }
  this.event_loop = function () {
    print("Event Loop Beginning. State: " + self.state + "\n");
    switch(self.state) {
      case 0:
        var login_button = self.view.getElement("#login_button");
        var home_button = self.view.getElement("#btn-vendors-index");
        // i.e. we didn't logout before
        if ( ! home_button.isNull == true) { self.state++; }
        if (login_button.isNull == true) {
          
          return;
        } else {
          self.view.fill("#code","110");
          sendKey(self.view,"Enter");
          self.state++;
        }
        break;
      case 1:
        var home_button = self.view.getElement("#btn-vendors-index");
        if (home_button.isNull != true) {
          self.view.click(home_button);
          self.state++;
        } else {
          print("waiting for home_button to be present\n");
        }
      default:
        clearInterval(self.interval_id);
        if (self.next_func) {
          setTimeout(self.next_func,100);
        }
        break;
    } // end switch state
    print("Event Loop Ending. State: " + self.state + "\n");
  } // end event_loop
}


