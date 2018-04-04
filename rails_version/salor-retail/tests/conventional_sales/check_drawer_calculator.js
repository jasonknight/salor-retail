env.modules.CheckDrawerCalculator = function () {
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
    print("CheckDrawerCalculator Beginning. State: " + self.state + "\n");
    switch(self.state) {
      case 0:
        self.view.click("#end_of_day_button");
        self.state++;
      break;  
      case 1:
        if (self.view.ready()) {
          var total = self.view.getContentOfElement("#eod-drawer-total");
         
          if (total.indexOf("167.00") == -1) {
            fail("eod drawer total did not contain 167.00");
            print( dump(total) );
          }
          self.state++;
        }
      break;
      case 2:
        self.view.fill("#eod_piece_5000","1");
        self.view.click("#eod_piece_5000");
        sendKey(self.view,"Tab");
        self.state++;
      break;
      case 3:
        if (self.view.getContentOfElement("#eod-calculator-difference").indexOf("117.00") == -1) {
          fail("Case 3 Difference at this point should be 117.00");
        }
        self.state++;
      break;
      case 4:
        self.view.fill("#eod_piece_2000",   "1");
        self.view.fill("#eod_piece_1000",   "6"); 
        self.view.fill("#eod_piece_500",    "6"); 
        self.view.fill("#eod_piece_100",    "3"); 
        self.view.fill("#eod_piece_50",     "2");
        self.view.fill("#eod_piece_25",     "4");
        self.view.fill("#eod_piece_10",     "10");
        self.view.fill("#eod_piece_5",      "20");
        self.view.click("#eod_piece_5000");
        sendKey(self.view,"Tab");
        self.state++;
      break;
      case 5:
        self.state++; // give some time for update
      break;
      case 6:
        var diff = self.view.getContentOfElement("#eod-calculator-difference");
        if (diff.indexOf("0.00") == -1) {
          fail("Case 5 Difference at this point should be 0.00 but is: " + diff);
        }
        self.state++;
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
