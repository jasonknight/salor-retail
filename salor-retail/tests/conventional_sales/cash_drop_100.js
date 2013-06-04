env.modules.CashDrop = function () {
  var self = this;
  this.state = 0;
  this.interval = 900;
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
    print("CashDrop100 Beginning. State: " + self.state + "\n");
    switch(self.state) {
      /////////////////////////////////
      //  Show cash drop
      ////////////////////////////////
      case 0:
        
        if (self.view.getElement("#header_drawer_amount").isVisible == true) {
          var drawer_total = self.view.getContentOfElement("#header_drawer_amount");
          if (drawer_total.indexOf("$0.00") == -1) {
            fatal("Drawer amount must be $0.00 but is " + drawer_total);
          } else {
            // we make a cash drop of 100
            var button = self.view.getElement("#header_cash_drop");
            if (button.isNull == true) {
              fatal("Failed to acquire button #header_cash_drop");
            } else {
              self.view.click(button);
              self.state++;           
            }
          }
        } // if visible
        break;
      ////////////////////////////////
      case 1:
        var cash_drop = self.view.getElement("#cash_drop");
        if (cash_drop.isVisible == true) {
          self.view.fill("#cash_drop_amount","100");
          var button = self.view.getElement("#confirm_cash_drop");
          self.view.click(button);
          self.state++;
        }
        break;
      /////////////////////////////////
      //  Verify drop
      ////////////////////////////////
      case 2:
        var drawer_amount = self.view.getContentOfElement("#header_drawer_amount");
        if (drawer_amount.indexOf("$100.00") == -1) {
          fail("Cash Drop of 100 failed");
        } else {
          self.state++;
        }
        break;
      
      default:
        clearInterval(self.interval_id);
        if (self.next_func) {
          setTimeout(self.next_func,100);
        } 
        break;
    } // end switch self.state
  } // end event_loop
}
