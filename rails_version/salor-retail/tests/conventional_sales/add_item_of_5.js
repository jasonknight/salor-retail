env.modules.Add5 = function () {
  var self = this;
  this.state = 0;
  this.interval = 800;
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
    print("Add 5 Beginning. State: " + self.state + "\n");
    switch(self.state) {
      /////////////////////////////////////////////
      //  Add an item of 5
      ////////////////////////////////////////////
      case 0:
        self.tries = 0;
        var complete_order_popup = self.view.getElement("#complete_order");
        if (complete_order_popup.isVisible == true) {
          if (self.tries < 3) {
            fatal("xxx Complete order popup needs to be hidden");
          } else {
            self.tries++;
            return;
          }
        }
        self.tries = 0;
        var input = self.view.getElement("#keyboard_input");
        self.view.fill(input,"5.00");
        sendKey(self.view,"Enter");
        var complete_button = self.view.getElement("#print_receipt_button");
        self.view.click(complete_button);
        self.state++;
        break;
      case 1:
        var complete_order_popup = self.view.getElement("#complete_order");
        if (complete_order_popup.isVisible == true) {
          sendText(self.view,"10.50");
          self.state++;
        } else {
          print("Waiting to send 10.50 when complete_order_popup is shown");
          var complete_button = self.view.getElement("#print_receipt_button");
          self.view.click(complete_button);
        }
        break;
      case 2:
        var total = self.view.getContentOfElement("#complete_order_total");
        var change = self.view.getContentOfElement("#complete_order_change");
        if (total.indexOf("5.00") == -1) {
          fatal("Order Total should be 5.00");
        } else if (change.indexOf("5.50") == -1) {
          fatal("Change should be 5.50 at case 9");
          self.state++;
        } else {
          var button = self.view.getElement("#confirm_complete_order_button");
          self.view.click(button);
          self.state++;
        }
        break;
      case 3:
        var drawer_amount = self.view.getContentOfElement("#header_drawer_amount");
        if (drawer_amount.indexOf("115.00") == -1) {
          // It may take some time for the element to update...
          if (self.tries < 3) {
            self.tries++;
          } else {
            fatal("Add item of $5.00 failed or cash drawer failed to update to value 115.00");
          }
        } else {
          var button = self.view.getElement("#cancel_complete_order_button");
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
