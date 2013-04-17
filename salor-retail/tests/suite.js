include("login.js");
include("choose_register.js");
include("conventional_sales/cash_drop_100.js");
include("conventional_sales/add_item_of_10.js");
include("conventional_sales/add_item_of_5.js");
include("conventional_sales/add_item_of_20.js");
include("conventional_sales/add_item_of_40.js");
include("conventional_sales/add_buybackitem_of_10.js");
include("conventional_sales/add_buybackitem_of_10and20.js");
include("conventional_sales/add_item_of_4.js");
var VIEW = new Chrome("ConventionalSalesMachine");

/*
  The idea here is that all the tests are made up of smaller
  tests that fit together as a chain, i.e. with calling
  test.next(other_test.run); 
  
  So at the end of the test, the next test is run, and
  either succeeds or fails. 
  
  This makes it easier for us to create/tweak tests alone, and
  then string them together to create one big test, and then
  at the very end, test the tests :) Which is essentially what
  the testing manual does. As you go along you verify order
  total, change, and drawer amount, and then at the end
  you verify the day report.
  
*/

var login             = new env.modules.LoginMachine();
    login.view        = VIEW; // We reuse the same view here because we aren't perf testing.
                              // Thus we reuse the cache, localdb, log, and cookies etc.
var choose            = new env.modules.ChooseRegister();
    choose.view       = VIEW;
var cash_drop         = new env.modules.CashDrop();
    cash_drop.view    = VIEW;
var add_10            = new env.modules.Add10();
    add_10.view       = VIEW;
var add_5             = new env.modules.Add5();
    add_5.view        = VIEW;
var add_20            = new env.modules.Add20();
    add_20.view       = VIEW
var add_40            = new env.modules.Add40();
    add_40.view       = VIEW
var add_buyback_10            = new env.modules.AddBuyback10();
    add_buyback_10.view       = VIEW;
var add_buyback_10and20       = new env.modules.AddBuyback10And20();
    add_buyback_10and20.view  = VIEW;
var add_4             = new env.modules.Add4();
    add_4.view        = VIEW;
login.run("http://localhost:3000").next(function () { 
  //cash_drop.run("http://localhost:3000/orders/new").next(function () {
    //choose.run("http://localhost:3000/cash_registers").next(env.report);
    add_4.run("http://localhost:3000/orders/new").next(env.report);
  //}); // end sales.run
}); // end login.run


