env.modules.AddBuyback10And20 = function () {
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
    print("Add10and20Beginning. State: " + self.state + "\n");
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
        self.tries = 0;
        break;
      case 2:
        var input = self.view.getElement("#keyboard_input");
        self.view.fill(input,"20.00");
        sendKey(self.view,"Enter");
        self.state++;
      break;
      case 3:
        self.state++;
      break;
      // Edit the first item
      case 4:
        var items = self.view.getElements(".pos-item-name");
        var first_item = items["1"];
        if (first_item.isVisible == true) {
          self.view.mouseDown(first_item);
          self.state++;
          self.tries = 0;
        } else {
          self.tries++;
          if (self.tries > 4) {
            fatal("Item never appeared");
          }
        }
      break;
      case 5:
        if (self.view.ready() == true) {
          var item_menu = self.view.getElement("#order_item_edit_name");
          if (item_menu.isVisible == true) {
            var button = self.view.getElement("#item_menu_buyback");
            self.view.click(button);
            var button = self.view.getElement("#item_menu_done");
            self.view.click(button);
            self.tries = 0;
            self.state++;
          } else {
            self.tries++;
            if (self.tries > 4) {
              fatal("item menu div never showed up");
            }
          }
        }
      break;
      case 6:
        if (self.view.ready() == true) {
          var items = self.view.getElements(".pos-item-price");
          var first_item = items["1"];
          if (first_item.isVisible) {
            self.tries = 0;
            if ( self.view.getContentOfElement(first_item.id).indexOf("0.00") == -1) {
              fatal("Item was not changed to buyback");
            } else {
              self.view.click(first_item);
              self.state++;
            }
          } else {
            self.tries++;
            if (self.tries > 4) {
              fatal("couldn't grab pos-item-price");
            }
          } 
        }
      break;
      case 7:
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
      case 8:
        self.view.executeJS("$(\"input[name='key_2_0']\").trigger('mousedown');");
        self.view.executeJS("$(\"input[name='key_accept']\").trigger('mousedown');");
        self.state++;
      break;
      // Edit the second item
      case 9:
        var items = self.view.getElements(".pos-item-name");
        var first_item = items["0"];
        if (first_item.isVisible == true) {
          print(dump(first_item));
          self.view.mouseDown(first_item);
          self.state++;
          self.tries = 0;
        } else {
          self.tries++;
          if (self.tries > 4) {
            fatal("Item never appeared");
          }
        }
      break;
      case 10:
        if (self.view.ready() == true) {
          var item_menu = self.view.getElement("#order_item_edit_name");
          if (item_menu.isVisible == true) {
            var button = self.view.getElement("#item_menu_buyback");
            self.view.click(button);
            var button = self.view.getElement("#item_menu_done");
            self.view.click(button);
            self.tries = 0;
            self.state++;
          } else {
            self.tries++;
            if (self.tries > 4) {
              fatal("item menu div never showed up");
            }
          }
        }
      break;
      case 11:
        if (self.view.ready() == true) {
          var items = self.view.getElements(".pos-item-price");
          var first_item = items["0"];
          if (first_item.isVisible) {
            self.tries = 0;
            if ( self.view.getContentOfElement(first_item.id).indexOf("0.00") == -1) {
              fatal("Item was not changed to buyback");
            } else {
              self.view.click(first_item);
              self.state++;
            }
          } else {
            self.tries++;
            if (self.tries > 4) {
              fatal("couldn't grab pos-item-price");
            }
          } 
        }
      break;
      case 12:
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
      case 13:
        self.view.executeJS("$(\"input[name='key_2_1']\").trigger('mousedown');");
        self.view.executeJS("$(\"input[name='key_accept']\").trigger('mousedown');");
        self.state++;
      break;
      // continue on
      
      
      case 14:
        var complete_button = self.view.getElement("#print_receipt_button");
        self.view.click(complete_button);
        self.state++;
      break;
      case 15:
        var complete_order_popup = self.view.getElement("#complete_order");
        if (complete_order_popup.isVisible == true) {
          var total = self.view.getContentOfElement("#complete_order_total");
          var change = self.view.getContentOfElement("#complete_order_change");
          if (total.indexOf("-3.00") == -1) {
            fail("Order Total should be -3.00");
          } else if (change.indexOf("3.00") == -1) {
            fail("Change should be 3.00 at case 13");
          }
          var button = self.view.getElement("#confirm_complete_order_button");
          self.view.click(button);
          self.state++;
        } else {
          print("Waiting for complete order popup");
        }
        break;
      case 16:
        if (self.view.ready() == true) {
          self.state++; //just waiting a bit
        }
      case 17:
        var drawer_amount = self.view.getContentOfElement("#header_drawer_amount");
        print("Drawer amount is: " + drawer_amount);
        if (drawer_amount.indexOf("156.00") == -1) {
          // It may take some time for the element to update...
          if (self.tries < 3) {
            self.tries++;
          } else {
            fatal("Add 2 items of buyback item failed or cash drawer failed to update");
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
