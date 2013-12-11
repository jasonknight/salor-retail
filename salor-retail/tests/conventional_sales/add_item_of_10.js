env.modules.Add10 = function () {
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
    print("Add 10 Loop Beginning. State: " + self.state + "\n");
    switch(self.state) {
      /////////////////////////////////////////////
      //  Verify that we are at the POS screen
      ////////////////////////////////////////////
      case 0:
        var input = self.view.getElement("#keyboard_input");
        if (input.isVisible == true) {
          // excellent, we are at the pos screen
          self.state++;
        }
        break;
      /////////////////////////////////////////////
      //  Add an item of 10
      ////////////////////////////////////////////
      case 1:
        self.tries = 0;
        var input = self.view.getElement("#keyboard_input");
        self.view.fill(input,"10.00");
        sendKey(self.view,"Enter");
        var complete_button = self.view.getElement("#print_receipt_button");
        self.view.click(complete_button);
        self.state++;
        break;
      case 2:
        var complete_order_popup = self.view.getElement("#complete_order");
        if (complete_order_popup.isVisible == true) {
          var total = self.view.getContentOfElement("#complete_order_total");
          var change = self.view.getContentOfElement("#complete_order_change");
          if (total.indexOf("10.00") == -1) {
            fatal("Order Total should be 10.00");
          } else if (change.indexOf("0.00") == -1) {
            fatal("Change should be 0.00 at case 5");
          } else {
            var button = self.view.getElement("#confirm_complete_order_button");
            self.view.click(button);
            self.state++;
          }
        } else {
          print("Waiting for complete order popup");
        }
        break;
      case 3:
        var drawer_amount = self.view.getContentOfElement("#header_drawer_amount");
        print("Drawer amount is: " + drawer_amount);
        if (drawer_amount.indexOf("110.00") == -1) {
          // It may take some time for the element to update...
          if (self.tries < 3) {
            self.tries++;
          } else {
            fatal("Add item of $10.00 failed or cash drawer failed to update");
          }
        } else {
          var button = self.view.getElement("#cancel_complete_order_button");
          print("button is: " + dump(button));
          self.view.click(button);
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
