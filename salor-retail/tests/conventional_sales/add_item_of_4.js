env.modules.Add4 = function () {
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
    print("Add4 Beginning. State: " + self.state + "\n");
    switch(self.state) {
      /////////////////////////////////////////////
      //  Add an item of 4
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
        self.view.fill(input,"4.00");
        sendKey(self.view,"Enter");
        var complete_button = self.view.getElement("#print_receipt_button");
        self.view.click(complete_button);
        self.state++;
        break;
      case 1:
        var complete_order_popup = self.view.getElement("#complete_order");
        if (complete_order_popup.isVisible == true) {
          sendText(self.view,"10.00");
          self.state++;
        } else {
          print("Waiting to send 10.50 when complete_order_popup is shown");
          var complete_button = self.view.getElement("#print_receipt_button");
          self.view.click(complete_button);
        }
        break;
      case 2:
        var button = self.view.getElement("#select_widget_button_for_payment_type_0");
        if (button.isVisible == true) {
          self.view.click(button);
          self.state++;
          self.tries = 0;
        } else {
          self.tries++;
          if (self.tries >= 4 ) {
            fatal("select widget button never showed");
          }
        }
        break;
      case 3:
        self.state++; //pause
      break;
      case 4:
        var button = self.view.getElement("#active_select_ByCard");
        //print(dump(button));
        if (button.isNull != true) { // sometime isVisible is false even when it's visible...
          self.view.click(button);
          self.state++;
          self.tries = 0;
        } else {
          self.tries++;
          if (self.tries >= 4 ) {
            fail("active widget button never showed");
          }
        }
        break;
      case 5:
        var total = self.view.getContentOfElement("#complete_order_total");
        var change = self.view.getContentOfElement("#complete_order_change");
        if (total.indexOf("4.00") == -1) {
          fatal("Order Total should be 4.00");
        } else if (change.indexOf("6.00") == -1) {
          fatal("Change should be 6.00 at case 4");
          self.state++;
        } else {
          var button = self.view.getElement("#confirm_complete_order_button");
          self.view.click(button);
          self.state++;
        }
        break;
      case 6:
        var drawer_amount = self.view.getContentOfElement("#header_drawer_amount");
        if (drawer_amount.indexOf("150.00") == -1) {
          // It may take some time for the element to update...
          if (self.tries < 3) {
            self.tries++;
          } else {
            fatal("Add item of $4.00 failed or cash drawer failed to update to value 150.00");
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
