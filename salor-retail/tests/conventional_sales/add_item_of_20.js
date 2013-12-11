env.modules.Add20 = function () {
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
    print("Add20 Beginning. State: " + self.state + "\n");
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
        self.view.fill(input,"20.00");
        sendKey(self.view,"Enter");
        var complete_button = self.view.getElement("#print_receipt_button");
        self.view.click(complete_button);
        self.state++;
        break;
      case 1:
        var complete_order_popup = self.view.getElement("#complete_order");
        if (complete_order_popup.isVisible == true) {
          var button = self.view.getElement("#payment_amount_0_kbd");
          self.view.click(button);
          self.state++;
          self.tries = 0;
        } else {
          var complete_button = self.view.getElement("#print_receipt_button");
          self.view.click(complete_button);
          print("Waiting to click on kdb when complete_order_popup is shown");
        }
        break;
      case 2:
       
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
      case 3:
        keys = ['2_1','3_1','3_2','3_1','3_1','accept'];
        for (var i = 0; i < keys.length; i++) {
          //var key = self.view.getElement("input[name='key_"+keys[i]+"']");
          self.view.executeJS("$(\"input[name='key_"+keys[i]+"']\").trigger('mousedown');");
          //print("$(\"input[name='key_"+keys[i]+"']\").trigger('mousedown');");
        }
        self.state++;
        break;
      case 4:
        var button = self.view.getElement("#add_payment_method_button");
        self.view.click(button);
        self.state++;
      break;
      case 5:
        var newpm = self.view.getContentOfElement("#select_widget_button_for_payment_type_1");
        if (newpm.indexOf("Debit") == -1) {
          fail("New payment method is expected to be Debit");
        }
        var button = self.view.getElement("#payment_amount_1_kbd");
        self.view.click(button);
        self.state++;
        self.tries = 0;
      case 6:
        var kbd = self.view.getElement(".ui-keyboard");
        if (kbd.isVisible == false) {
          if (self.tries > 5) {
            fatal("keyboard never showed up");
          } else {
            self.tries++;
          }
        } else {
          self.state++;
        }
        break; 
      case 7:
        keys = ['2_0','3_1','3_2','3_1','3_1','accept'];
        for (var i = 0; i < keys.length; i++) {
          //var key = self.view.getElement("input[name='key_"+keys[i]+"']");
          self.view.executeJS("$(\"input[name='key_"+keys[i]+"']\").trigger('mousedown');");
          //print("$(\"input[name='key_"+keys[i]+"']\").trigger('mousedown');");
        }
        self.state++;
        break;
      case 8:
        var total = self.view.getContentOfElement("#complete_order_total");
        var change = self.view.getContentOfElement("#complete_order_change");
        if (total.indexOf("20.00") == -1) {
          fatal("Order Total should be 20.00");
        } else if (change.indexOf("10.00") == -1) {
          fatal("Change should be 10.00 at case 8");
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
        if (drawer_amount.indexOf("125.00") == -1) {
          // It may take some time for the element to update...
          if (self.tries < 3) {
            self.tries++;
          } else {
            fatal("Add item of $20.00 failed or cash drawer failed to update to value 125.00");
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
