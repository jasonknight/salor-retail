env.modules.Add20Discount= function () {
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
    print("Add20Discount Beginning. State: " + self.state + "\n");
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
        self.view.fill(input,"20.00");
        sendKey(self.view,"Enter");
        self.state++;
        break;
      case 2:
        var total = self.view.getContentOfElement("#pos_order_total");
        if (total.indexOf("20.00") != -1) {
          self.state++;
        } else {
          print("Waiting for total to update");
        }
        break;
      case 3:
        var button = self.view.click("#configuration_button");
        self.state++;
      break;
      case 4:
        var options = self.view.getElement("#order_options");
        if (options.isVisible == true) {
          self.state++;
        } else {
          print("Waiting on order options");
        }
      break;
      case 5:
        self.view.fill("#option_order_rebate_input","5");
        self.view.click("#option_order_rebate_button");
        self.view.click("#order_options_delete");
        self.state++;
      break;
      case 6:
        var total = self.view.getContentOfElement("#pos_order_total");
        if (total.indexOf("19.00") != -1) {
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
            self.view.click("#add_payment_method_button");
            self.state++;
        } else {
          print("Waiting for complete order popup");
        }
      break;
      case 8:
        var button = self.view.getElement("#select_widget_button_for_payment_type_1");
        if (button.isVisible == true) {
            if (self.view.getContentOfElement("#select_widget_button_for_payment_type_1").indexOf("Debit") == -1) {
              fail("Second payment method should be Debit");
            }
            self.view.fill("#payment_amount_0","9");
            self.view.fill("#payment_amount_1","10");
            self.state++;
        } else {
          print("Waiting for select_widget_button_for_payment_type_1");
        }
      break;
      case 9:
        var complete_order_popup = self.view.getElement("#complete_order");
        if (complete_order_popup.isVisible == true) {
            var button = self.view.getElement("#confirm_complete_order_button");
            self.view.click(button);
            self.state++;
        } else {
          print("Waiting for complete order popup");
        }
      break;
      case 10:
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
