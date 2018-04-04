env.modules.Add10Discount= function () {
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
    print("Add10Discount Beginning. State: " + self.state + "\n");
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
        self.state++;
        break;
      case 2:
        var total = self.view.getContentOfElement("#pos_order_total");
        if (total.indexOf("10.00") != -1) {
          self.state++;
        } else {
          print("Waiting for total to update");
        }
        break;
      case 3: 
        self.view.click(".pos-item-rebate");
        self.state++;
        break;
      case 4:
        var kbd = self.view.getElement(".ui-keyboard");
         if (kbd.isVisible == false) {
            if (self.tries > 4) {
              fatal("keyboard never showed up");
            } else {
              self.tries++;
            }
         } else {
          self.state++;
         }
         break;
      case 5:
        self.view.fill(".inplaceeditinput",20);
        sendKey(self.view,"Enter");
        self.state++;
        break;
      case 6:
        var total = self.view.getContentOfElement("#pos_order_total");
        if (total.indexOf("8.00") != -1) {
          var complete_button = self.view.getElement("#print_receipt_button");
          self.view.click(complete_button);
          self.state++;
        } else {
          print("Waiting for total to update");
        }
        break;
      case 7:
        var complete_order_popup = self.view.getElement("#complete_order");
        if (complete_order_popup.isVisible == true) {
            var button = self.view.getElement("#confirm_complete_order_button");
            self.view.click(button);
            self.state++;
        } else {
          print("Waiting for complete order popup");
        }
        break;
      case 8:
        var total = self.view.getContentOfElement("#pos_order_total");
        if (total.indexOf("0.00") != -1) {
          var button = self.view.getElement("#cancel_complete_order_button");
          self.view.click(button);
          self.state++;
        } else {
          print("Waiting for total to update");
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
