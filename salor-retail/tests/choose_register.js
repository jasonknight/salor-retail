env.modules.ChooseRegister = function () {
  var self = this;
  this.state = 0;
  this.interval = 800; // make sure this allows enough time between steps. Otherwise
                        // we will have to make checks to ensure readyness
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
    print("Choose Register Beginning. State: " + self.state + "\n");
    switch(self.state) {
      case 0:
        if (self.view.ready() == true) {
          var registers = self.view.getElements(".choose-register-icon");
          var register = registers["0"];
          self.view.click(register);
          self.state++;
          self.tries = 0;
        } else {
          print("waiting for ready");
        }
        break;
      case 1:
        // pause a bit
          if (self.view.ready() == true) {
            self.state++;
          }
        break;
      case 2:
        if (self.view.ready() == true) {
          var input = self.view.getElement("#keyboard_input");
          if (input.isNull == false) {
            self.state++;
          } else {
            self.state++;
            fail("couldn't find keyboard_input");
          }
        }
      default:
        clearInterval(self.interval_id);
        if (self.next_func) {
          setTimeout(self.next_func,100);
        }
        break;
    } // end switch state
    print("Choose Register Ending. State: " + self.state + "\n");
  } // end event_loop
}


