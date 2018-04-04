env.modules.Add40 = function () {
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
    print("Add40 Beginning. State: " + self.state + "\n");
    switch(self.state) { 
      /////////////////////////////////////////////
      //  Add an item of 20
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
        self.view.fill(input,"40.00");
        sendKey(self.view,"Enter");
        var complete_button = self.view.getElement("#print_receipt_button");
        self.view.click(complete_button);
        self.state++;
        break;
      case 1:
        var complete_order_popup = self.view.getElement("#complete_order");
        if (complete_order_popup.isVisible == true) {
          self.state++;
        } else {
          var complete_button = self.view.getElement("#print_receipt_button");
          self.view.click(complete_button);
          print("Waiting to click on 50 piece when complete_order_popup is shown");
        }
        break;
      case 2:
       var button = self.view.getElement("#complete_piece_50");
       self.view.click(button);
       self.state++;
       break;
      case 3:
        var button = self.view.getElement("#add_payment_method_button");
        self.view.click(button);
        self.state++;
        self.tries = 0;
      break;
      case 4:
        var button = self.view.getElement("#select_widget_button_for_payment_type_1");
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
      case 5:
        var button = self.view.getElement("#active_select_OtherCredit");
        if (button.isVisible == true) {
          self.view.click(button);
          self.state++;

        } else {
          print("Waiting for OtherCredit to show up");
        }
        break;
      case 6:
          sendText(self.view,"5");
          self.state++;
          self.tries = 0;
      case 7:
        self.state++; // pause for ui update
      break;
      case 8:
        var total = self.view.getContentOfElement("#complete_order_total");
        var change = self.view.getContentOfElement("#complete_order_change");
        if (total.indexOf("40.00") == -1) {
          fail("Order Total should be 40.00");
        } else if (change.indexOf("15.00") == -1) {
          fail("Change should be 15.00 at case 8 but is " + change);
          self.state++;
        } else {
          var button = self.view.getElement("#confirm_complete_order_button");
          self.view.click(button);
          self.state++;
        }
        break;
      case 9:
        var button = self.view.getElement("#confirm_complete_order_button");
        self.view.click(button);
        self.state++;
        break;
      case 10:
        var drawer_amount = self.view.getContentOfElement("#header_drawer_amount");
        if (drawer_amount.indexOf("160.00") == -1) {
          // It may take some time for the element to update...
          if (self.tries < 3) {
            self.tries++;
          } else {
            fail("Add item of $40.00 failed or cash drawer failed to update to value 160.00");
            self.state++;
            var button = self.view.getElement("#cancel_complete_order_button");
            self.view.click(button);
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
