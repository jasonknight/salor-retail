env.modules.ConventionalSales = function () {
  var self = this;
  this.state = 0;
  this.interval = 1200;
  this.interval_id = null;
  this.next_func = null;
  this.tries = 0;
  this.run = function (start_url) {
    self.view.load(start_url);
    self.interval_id = setInterval(self.event_loop,self.interval);
    return self;
  } // end run
  this.next = function (next_func) {
    self.next_func = next_func;
  }
  
  this.event_loop = function () {
    print("Conventional Sales Event Loop Beginning. State: " + self.state + "\n");
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
      /////////////////////////////////////////////
      //  Verify that we are at the POS screen
      ////////////////////////////////////////////
      case 3:
        var input = self.view.getElement("#keyboard_input");
        if (input.isVisible == true) {
          // excellent, we are at the pos screen
          self.state++;
        }
        break;
      /////////////////////////////////////////////
      //  Add an item of 10
      ////////////////////////////////////////////
      case 4:
        self.tries = 0;
        var input = self.view.getElement("#keyboard_input");
        self.view.fill(input,"10.00");
        sendKey(self.view,"Enter");
        var complete_button = self.view.getElement("#print_receipt_button");
        self.view.click(complete_button);
        self.state++;
        break;
      case 5:
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
      case 6:
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
        
        
      /////////////////////////////////////////////
      //  Add an item of 5
      ////////////////////////////////////////////
      case 7:
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
      case 8:
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
      case 9:
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
      case 10:
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
        
        
        /////////////////////////////////////////////
      //  Add an item of 20
      ////////////////////////////////////////////
      case 11:
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
      case 12:
        var complete_order_popup = self.view.getElement("#complete_order");
        if (complete_order_popup.isVisible == true) {
          var button = self.view.getElement("#payment_amount_0_kbd");
          self.view.click(button);
          self.state++;
        } else {
          print("Waiting to click on kdb when complete_order_popup is shown");
        }
        break;
      case 13:
       self.tries = 0;
       var kbd = self.view.getElement(".ui-keyboard");
       print("kbd is: " + dump(kbd));
       if (kdb.isNull == true || kbd.isVisible == false) {
          if (self.tries > 4) {
            fatal("keyboard never showed up");
          } else {
            self.tries++;
          }
       } else {
        self.state++;
       }
       break;
      case 14:
        keys = ['2_1','3_1','3_2','3_1','3_1'];
        for (var i = 0; i < keys.length; i++) {
          //var key = self.view.getElement("input[name='key_"+keys[i]+"']");
          self.view.executeJS("$(\"input[name='key_"+keys[i]+"']\").click()");
        }
        self.state++;
        break;
      case 15:
        var button = 
        
      
        
      default:
        clearInterval(self.interval_id);
        if (self.next_func) {
          setTimeout(self.next_func,100);
        } 
        break;
    } // end switch self.state
  } // end event_loop
}
