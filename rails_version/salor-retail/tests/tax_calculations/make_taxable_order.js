env.modules.MakeTaxableOrder = function () {
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
    print("MakeTaxableOrder Beginning. State: " + self.state + "\n");
    switch(self.state) {
      case 0:
        if (self.view.ready()) {
          var input = self.view.getElement("#keyboard_input");
          self.view.fill(input,"10.00");
          sendKey(self.view,"Enter");
          self.state++;
        }
      break;
      case 1:
        self.state++; //a little pause
      break
      case 2:
        var tpamnt = self.view.getContentOfElement(".pos-item-tax_profile_amount");
        tpamnt = tpamnt.replace("%","");
        tpamnt = parseInt(tpamnt);
        if (! tpamnt > 0) {
          fail("Tax Amount was 0");
        } else {
          var total = self.view.getContentOfElement("#pos_order_total");
          var needle = (10.00 + ( 10.00 * (tpamnt / 100) ));
          needle = needle + "";
          if (total.indexOf(needle) == -1) {
            fail("Could not find " + needle + " in " + total);
          }
        }
        self.state++;
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
