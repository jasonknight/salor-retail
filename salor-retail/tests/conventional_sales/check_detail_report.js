env.modules.CheckDetailReport = function () {
  var self = this;
  this.state = 0;
  this.interval = 1300;
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
    print("CheckDetailReport Beginning. State: " + self.state + "\n");
    switch(self.state) {
      case 0:
        if (self.view.ready()) {
          self.view.click("#go_to_report_day");
          self.state++;
        }
      break;
      case 1:
        if (self.view.ready()) {
          var sumgross = self.view.getContentOfElement("#pos_sum_gross");
          if (sumgross.indexOf("106.00") == -1) {
            fail("Sum Gross Amount Wrong " + sumgross + " should be 106.00");
            print( dump(sumgross) );
          } 
          var incash = self.view.getContentOfElement("#pos_InCash_sum");
          if (incash.indexOf("71.00") == -1) {
            fail("In Cash Amount Wrong is " + incash + " should be 71.00");
            print( dump(incash) );
          } 
          var bycard = self.view.getContentOfElement("#pos_ByCard_sum");
          if (bycard.indexOf("30.00") == -1) {
            fail("Debit  Amount Wrong " + bycard + " should be 30.00");
          } 
          var other = self.view.getContentOfElement("#pos_OtherCredit_sum");
          if (other.indexOf("5.00") == -1) {
            fail("In OtherCredit Amount Wrong " + other + " should be 5.00");
          } 
          var negsum = self.view.getContentOfElement("#neg_sum_gross");
          if (negsum.indexOf("4.00") == -1) {
            fail("Neg Sum Amount Wrong " + negsum + " should be 4.00");
          } 
          var negincash = self.view.getContentOfElement("#neg_InCash_sum");
          if (negincash.indexOf("4.00") == -1) {
            fail("NegIn Cash Amount Wrong " + negincash + " should be 4.00");
          } 
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
